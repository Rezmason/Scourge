package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.system.Capabilities;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;

import net.rezmason.scourge.textview.styles.Style;
import net.rezmason.scourge.textview.styles.StyleSet;

using net.rezmason.scourge.textview.core.GlyphUtils;
using StringTools;

class UIBody extends Body {

    inline static var scrollEase:Float = 0.6;
    inline static var NATIVE_DPI:Float = 72;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 24;

    inline static var LINE_TOKEN:String = "ª÷º";

    var styleSet:StyleSet;

    var text:String;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var glyphWidthInPixels :Float;
    var glyphHeightInPixels:Float;
    var baseTransform:Matrix3D;

    var scrollFraction:Float;
    var scroll:Float;
    var scrollGoal:Float;
    var smoothScrolling:Bool;

    var numRows:Int;
    var numCols:Int;
    var numRowsForLayout:Int;
    var numGlyphsInLayout:Int;

    override function init():Void {

        styleSet = new StyleSet();

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        letterbox = false;

        glyphHeightInPixels = GLYPH_HEIGHT_IN_POINTS * Capabilities.screenDPI / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        var numGlyphColumns:Int = Std.int(Capabilities.screenResolutionX / glyphWidthInPixels);
        var numGlyphRows:Int = Std.int(Capabilities.screenResolutionY / glyphHeightInPixels);

        var numGlyphs:Int = numGlyphRows * numGlyphColumns;

        scroll = 0;
        scrollGoal = 0;
        smoothScrolling = false;

        for (id in 0...numGlyphs) {
            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = id;
            glyph.prime();
            glyph.set_paint(glyph.id);
            glyphs.push(glyph);
        }
    }

    override public function update(delta:Float):Void {
        updateScroll();
        styleSet.updateGlyphs(delta);
        super.update(delta);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);
        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        numRows = Std.int(rect.height * stageHeight / glyphHeightInPixels);
        numRowsForLayout = numRows;
        numRows++;
        numCols = Std.int(rect.width  * stageWidth  / glyphWidthInPixels );
        scrollFraction = 1 / numRowsForLayout;
        setGlyphScale(rect.width / numCols * 2, rect.height / numRowsForLayout * 2);

        reorderGlyphs();
        updateText(text);
    }

    public function scrollText(ratio:Float, smoothScrolling:Bool = true):Void {
        var pos:Float = (page.length - (numRows - 1)) * (1 - Math.max(0, Math.min(1, ratio)));

        this.smoothScrolling = smoothScrolling;

        if (smoothScrolling) scrollGoal = Std.int(pos);
        else setScroll(pos);
    }

    public function updateText(text:String):Void {
        if (text == null) text = "";
        this.text = text;

        if (numGlyphsInLayout == 0) return;

        // Simplify the text and wrap it to new lines as we construct the page

        var styleSigil:String = StyleSet.SIGIL;
        var styledLineReg:EReg = new EReg('(([^$styleSigil]$styleSigil*){$numCols})', 'g');

        function padLine(s) {
            // Pads a string until its length, ignoring sigils, is 1
            return StringTools.rpad(s, " ", numCols + s.split(styleSigil).length - 1);
        }

        function wrapLines(s) {
            // Splits a line into an array of lines whose length, ignoring sigils, is numCols
            var sp = styledLineReg.replace(s, '$1$LINE_TOKEN');
            if (sp.endsWith(LINE_TOKEN)) sp = sp.substr(0, sp.length - 1);
            return sp.split(LINE_TOKEN).map(padLine).join(LINE_TOKEN);
        }

        page = styleSet.extractFromText(text).split("\n").map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

        // Add blank lines to the end, to reach the minimum page length (numRows)

        var blankParagraph:String = "".rpad(" ", numCols);
        while (page.length < numRows) page.push(blankParagraph);

        // Count the sigils in each line, for style lookup

        var lineStyleIndex:Int = 0;
        lineStyleIndices = [lineStyleIndex];
        for (line in page) {
            lineStyleIndex += line.split(styleSigil).length - 1;
            lineStyleIndices.push(lineStyleIndex);
        }

        // Reset the scroll position to the bottom of the page

        scrollText(1, false);
    }

    inline function reorderGlyphs():Void {
        var id:Int = 0;
        for (row in 0...numRows) {
            for (col in 0...numCols) {
                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / numRowsForLayout - 0.5);
                var glyph:Glyph = glyphs[id++];
                glyph.set_pos(x, y, 0);
            }
        }

        numGlyphsInLayout = numRows * numCols;
        toggleGlyphs(glyphs.slice(0, numGlyphsInLayout), true);
        toggleGlyphs(glyphs.slice(numGlyphsInLayout), false);
    }

    inline function setScroll(pos:Float):Void {
        var scrollStart:Int = Std.int(pos);
        var id:Int = 0;
        var pageSegment:Array<String> = page.slice(scrollStart, scrollStart + numRows);
        var styleIndex:Int = lineStyleIndices[scrollStart];

        styleSet.removeAllGlyphs();

        var currentStyle:Style = styleSet.getStyleByIndex(styleIndex);
        for (line in pageSegment) {
            var index:Int = 0;
            for (index in 0...line.length) {
                if (line.charAt(index) == "§") {
                    currentStyle = styleSet.getStyleByIndex(++styleIndex);
                } else {
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(line.charCodeAt(index), glyphTexture.font);
                    currentStyle.addGlyph(glyph);
                }
            }
        }

        styleSet.updateGlyphs(0);

        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, (pos - scrollStart) * scrollFraction, 0);
    }

    inline function updateScroll():Void {
        if (smoothScrolling) {
            if (Math.abs(scrollGoal - scroll) < 0.0001) {
                scroll = scrollGoal;
                smoothScrolling = false;
            } else {
                scroll = scroll * scrollEase + scrollGoal * (1 - scrollEase);
            }

            setScroll(scroll);
        }
    }
}
