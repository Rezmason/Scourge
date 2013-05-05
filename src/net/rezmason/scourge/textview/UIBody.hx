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

    inline static var ease:Float = 0.6;

    var styleSet:StyleSet;

    var text:String;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    /*
    inline static var BOX_SIGIL:String = "ß";
    inline static var LINE_SIGIL:String = "¬";
    */

    inline static var NATIVE_DPI:Float = 72;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 24;
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
        var blank:Int = " ".charCodeAt(0);

        scroll = 0;
        scrollGoal = 0;
        smoothScrolling = false;

        //var sigils:EReg = ~/[ß¬]/;

        for (id in 0...numGlyphs) {
            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = id;
            glyphs.push(glyph);

            var x:Float = 0;
            var y:Float = 0;

            /*
            var char:String = strMatrix[row][col];
            if (sigils.match(char)) {
                var left  :Int = (col > 0            && sigils.match(strMatrix[row][col - 1])) ? 1 : 0;
                var right :Int = (col < NUM_COLS - 1 && sigils.match(strMatrix[row][col + 1])) ? 1 : 0;
                var top   :Int = (row > 0            && sigils.match(strMatrix[row - 1][col])) ? 1 : 0;
                var bottom:Int = (row < NUM_ROWS - 1 && sigils.match(strMatrix[row + 1][col])) ? 1 : 0;

                if (char == LINE_SIGIL) {
                    if (left & right == 1) top = bottom = 0;
                    if (top & bottom == 1) left = right = 0;
                }

                var flag:Int = (left << 0) | (right << 1) | (top << 2) | (bottom << 3);
                char = TestStrings.BOX_SYMBOLS.charAt(flag);
            }

            var charCode:Int = char.charCodeAt(0);
            */

            glyph.makeCorners();
            glyph.set_shape(x, y, 0, 1, 0);
            glyph.set_color(1, 1, 1);
            glyph.set_i(0);
            glyph.set_char(blank, glyphTexture.font);
            glyph.set_paint(glyph.id);
        }
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

    public function updateText(text:String):Void {
        if (text == null) text = "";
        this.text = text;

        if (numGlyphsInLayout == 0) return;

        text = styleSet.extractFromText(text);

        var styleSigil:String = StyleSet.SIGIL;
        var styledLineReg:EReg = new EReg('(([^$styleSigil]$styleSigil*){${numCols}})', 'g');
        var lineToken:String = "÷";
        var blankParagraph:String = "".rpad(" ", numCols);

        function padLine(s) return StringTools.rpad(s, " ", numCols + s.split(styleSigil).length - 1);

        function wrapLines(s) {
            var sp = styledLineReg.replace(s, '$1$lineToken');
            if (sp.endsWith(lineToken)) sp = sp.substr(0, sp.length - 1);
            return sp.split(lineToken).map(padLine).join(lineToken);
        }

        page = text.split("\n").map(wrapLines).join(lineToken).split(lineToken);
        while (page.length < numRows) page.push(blankParagraph);

        var lineStyleIndex:Int = 0;
        lineStyleIndices = [0];
        for (line in page) {
            lineStyleIndex += line.split(styleSigil).length - 1;
            lineStyleIndices.push(lineStyleIndex);
        }

        scrollChars(1, false);
    }

    function setScroll(pos:Float):Void {
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

        styleSet.updateGlyphs(true);

        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, (pos - scrollStart) * scrollFraction, 0);
    }

    public function scrollChars(ratio:Float, smoothScrolling:Bool = true):Void {
        var pos:Float = (page.length - (numRows - 1)) * (1 - Math.max(0, Math.min(1, ratio)));

        this.smoothScrolling = smoothScrolling;

        if (smoothScrolling) scrollGoal = Std.int(pos);
        else setScroll(pos);
    }

    override public function update():Void {
        updateScroll();
        styleSet.updateGlyphs();
        super.update();
    }

    inline function updateScroll():Void {
        if (smoothScrolling) {
            if (Math.abs(scrollGoal - scroll) < 0.0001) {
                scroll = scrollGoal;
                smoothScrolling = false;
            } else {
                scroll = scroll * ease + scrollGoal * (1 - ease);
            }

            setScroll(scroll);
        }
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
}
