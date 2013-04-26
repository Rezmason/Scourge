package net.rezmason.scourge.textview;

import nme.geom.Rectangle;
import nme.system.Capabilities;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIBody extends Body {

    var text:String;
    var textDocument:Array<Array<String>>;
    /*
    inline static var BOX_SIGIL:String = "ß";
    inline static var LINE_SIGIL:String = "¬";
    */
    inline static var GLYPH_WIDTH_IN_INCHES :Float = 18 / 72 / 2;
    inline static var GLYPH_HEIGHT_IN_INCHES:Float = 28 / 72 / 2;
    var glyphWidthInPixels :Float;
    var glyphHeightInPixels:Float;

    var numRows:Int;
    var numCols:Int;
    var numGlyphsInLayout:Int;

    override function init():Void {

        var dpi:Float = Capabilities.screenDPI;
        glyphWidthInPixels  = GLYPH_WIDTH_IN_INCHES  * dpi;
        glyphHeightInPixels = GLYPH_HEIGHT_IN_INCHES * dpi;

        var numGlyphColumns:Int = Std.int(Capabilities.screenResolutionX / glyphWidthInPixels);
        var numGlyphRows:Int = Std.int(Capabilities.screenResolutionY / glyphHeightInPixels);

        var numGlyphs:Int = numGlyphRows * numGlyphColumns;

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

            var charCode:Int = (id % 26) + 65;

            glyph.makeCorners();
            glyph.set_shape(x, y, 0, 1, 0);
            glyph.set_color(1, 1, 1, 1);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(glyph.id);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {

        super.adjustLayout(stageWidth, stageHeight, rect);

        rect = rect.clone();
        if (stageWidth  == 0) stageWidth  = 1;
        if (stageHeight == 0) stageHeight = 1;
        if (rect.width  == 0) rect.width  = 1 / stageWidth;
        if (rect.height == 0) rect.height = 1 / stageHeight;

        glyphTransform.identity();

        var rectWidthInPixels :Float = rect.width  * stageWidth;
        var rectHeightInPixels:Float = rect.height * stageHeight;

        numRows = Std.int(rectHeightInPixels / glyphHeightInPixels);
        numCols = Std.int(rectWidthInPixels  / glyphWidthInPixels );
        numGlyphsInLayout = numRows * numCols;

        var glyphWidth :Float = rectWidthInPixels  / stageWidth  / numCols;
        var glyphHeight:Float = rectHeightInPixels / stageHeight / numRows;

        glyphTransform.appendScale(glyphWidth * 2, glyphHeight * 2, 1);

        transform.identity();
        transform.appendScale(1, -1, 1);

        for (ike in 0...numGlyphsInLayout) {
            var glyph:Glyph = glyphs[ike];
            var col:Int = glyph.id % numCols;
            var row:Int = Std.int((glyph.id - col) / numCols);
            var x:Float = ((col + 0.5) / numCols - 0.5);
            var y:Float = ((row + 0.5) / numRows - 0.5);
            /*
            if (row >= numRows) glyph.set_color(1, 0, 0, 1);
            else glyph.set_color(1, 1, 0, 1);
            */
            glyph.set_shape(x, y, 0, 1, 0);
        }

        toggleGlyphs(glyphs.slice(0, numGlyphsInLayout), true);
        toggleGlyphs(glyphs.slice(numGlyphsInLayout), false);

        updateText(text);
        update();
    }

    public function updateText(text:String):Void {
        if (text == null) text = "";
        this.text = text;

        textDocument = text.split("\n").map(function(a) return a.split(""));

        var row:Int = 0;
        var col:Int = 0;

        var blank:Int = " ".charCodeAt(0);

        for (paragraph in textDocument) {
            for (letter in paragraph) {
                var glyph:Glyph = glyphs[row * numCols + col];
                var charCode:Int = letter.charCodeAt(0);
                glyph.set_char(charCode, glyphTexture.font);
                col++;

                if (col >= numCols) {
                    row++;
                    col = 0;
                    if (row >= numRows) break;
                }
            }

            if (row >= numRows) break;
            for (ike in col...numCols) glyphs[row * numCols + ike].set_char(blank, glyphTexture.font);

            row++;
            col = 0;

            if (row >= numRows) break;
        }

        for (ike in row...numRows) for (jen in 0...numCols) glyphs[ike * numCols + jen].set_char(blank, glyphTexture.font);
    }
}
