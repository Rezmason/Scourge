package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.system.Capabilities;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;

import net.rezmason.scourge.textview.styles.Style;
import net.rezmason.scourge.textview.styles.StyleSet;

using net.rezmason.scourge.textview.core.GlyphUtils;
using StringTools;

class UIBody extends Body {

    inline static var glideEase:Float = 0.6;
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

    var currentScrollPos:Float;
    var glideGoal:Float;
    var gliding:Bool;

    var dragging:Bool;
    var dragStartY:Float;
    var dragStartPos:Float;

    var numRows:Int;
    var numCols:Int;
    var numRowsForLayout:Int;
    var numGlyphsInLayout:Int;

    public var numLines(get, null):Int;
    public var numScrollPositions(get, null):Int;

    override function init():Void {

        styleSet = new StyleSet();

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        letterbox = false;
        crop = false;

        glyphHeightInPixels = GLYPH_HEIGHT_IN_POINTS * Capabilities.screenDPI / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        var numGlyphColumns:Int = Std.int(Capabilities.screenResolutionX / glyphWidthInPixels);
        var numGlyphRows:Int = Std.int(Capabilities.screenResolutionY / glyphHeightInPixels);

        var numGlyphs:Int = numGlyphRows * numGlyphColumns;

        currentScrollPos = Math.NaN;
        gliding = false;

        for (glyphID in 0...numGlyphs) {
            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = glyphID;
            glyph.prime();
            glyph.set_paint(id << 16);
            glyphs.push(glyph);
        }
    }

    override public function update(delta:Float):Void {
        updateGlide();
        styleSet.updateGlyphs(delta);
        taperScrollEdges();
        super.update(delta);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);
        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        numRows = Std.int(rect.height * stageHeight / glyphHeightInPixels);
        numRowsForLayout = numRows;
        numRows++;
        numCols = Std.int(rect.width  * stageWidth  / glyphWidthInPixels );
        setGlyphScale(rect.width / numCols * 2, rect.height / numRowsForLayout * 2);

        reorderGlyphs();
        updateText(text);
    }

    public function glideTextToPos(pos:Float):Void {
        gliding = true;
        glideGoal = Std.int(Math.max(0, Math.min(numScrollPositions - 1, pos)));
    }

    public function updateText(text:String):Void {
        if (text == null) text = "";
        this.text = text;

        if (numGlyphsInLayout == 0) return;

        // Simplify the text and wrap it to new lines as we construct the page

        var styledLineReg:EReg = new EReg('(([^${StyleSet.SIGIL}]${StyleSet.SIGIL}*){$numCols})', 'g');

        function padLine(s) {
            // Pads a string until its length, ignoring sigils, is 1
            return StringTools.rpad(s, " ", numCols + s.split(StyleSet.SIGIL).length - 1);
        }

        function wrapLines(s) {
            // Splits a line into an array of lines whose length, ignoring sigils, is numCols
            var sp = styledLineReg.replace(s, '$1$LINE_TOKEN');
            if (sp.endsWith(LINE_TOKEN)) sp = sp.substr(0, sp.length - LINE_TOKEN.length);
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
            lineStyleIndex += line.split(StyleSet.SIGIL).length - 1;
            lineStyleIndices.push(lineStyleIndex);
        }

        if (Math.isNaN(currentScrollPos)) setScrollPos(numScrollPositions - 1);
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

    inline function setScrollPos(pos:Float):Void {

        currentScrollPos = pos;

        var scrollStartIndex:Int = Std.int(currentScrollPos);
        var id:Int = 0;
        var pageSegment:Array<String> = page.slice(scrollStartIndex, scrollStartIndex + numRows);
        var styleIndex:Int = lineStyleIndices[scrollStartIndex];

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
                    glyph.set_z(0);
                }
            }
        }

        styleSet.updateGlyphs(0);

        taperScrollEdges();

        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, (currentScrollPos - scrollStartIndex) / numRowsForLayout, 0);
    }

    inline function taperScrollEdges():Void {
        var offset:Float = currentScrollPos % 1;
        var lastRow:Int = (numRows - 1) * numCols;
        var glyph:Glyph;
        for (col in 0...numCols) {
            glyph = glyphs[col];
            glyph.set_color(glyph.get_r() * (1 - offset), glyph.get_g() * (1 - offset), glyph.get_b() * (1 - offset));

            glyph = glyphs[lastRow + col];
            glyph.set_color(glyph.get_r() * offset, glyph.get_g() * offset, glyph.get_b() * offset);
        }
    }

    inline function updateGlide():Void {
        if (gliding) {
            if (Math.abs(glideGoal - currentScrollPos) < 0.0001) {
                setScrollPos(glideGoal);
                gliding = false;
            } else {
                setScrollPos(currentScrollPos * glideEase + glideGoal * (1 - glideEase));
            }
        }
    }

    override public function interact(id:Int, interaction:Interaction, x:Float, y:Float):Void {
        if (dragging) {
            switch (interaction) {
                case DROP, CLICK: dragging = false;
                case ENTER, EXIT, MOVE: glideTextToPos(dragStartPos + (dragStartY - y) * numRowsForLayout);
                case _:
            }
        } else if (id == 0) {
            if (interaction == DOWN) {
                dragging = true;
                dragStartY = y;
                dragStartPos = currentScrollPos;
            }
        } else {
            // buttons and text fields!
        }
    }

    inline function get_numLines():Int { return page.length; }

    inline function get_numScrollPositions():Int { return page.length - numRows + 1; }
}
