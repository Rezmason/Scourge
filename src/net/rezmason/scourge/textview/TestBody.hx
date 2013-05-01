package net.rezmason.scourge.textview;

import nme.geom.Rectangle;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;

using net.rezmason.scourge.textview.core.GlyphUtils;

class TestBody extends Body {

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
    "";

    override function init():Void {

        var numCols:Int = 30;
        var numRows:Int = 30;
        var totalChars:Int = numCols * numRows;

        for (ike in 0...totalChars) {

            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = ike;
            glyphs.push(glyph);

            var col:Int = ike % numCols;
            var row:Int = Std.int(ike / numCols);

            var x:Float = (col + 0.5) / numCols - 0.5;
            var y:Float = (row + 0.5) / numRows - 0.5;
            var z:Float = -0.5;

            z *= Math.cos(row / numRows * Math.PI * 2);
            z *= Math.cos(col / numCols * Math.PI * 2);

            var r:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var g:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var b:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            //*
            r = row / numRows;
            g = col / numCols;
            b = Math.cos(r) * Math.cos(g) * 0.5;
            /**/

            r *= 0.6;
            g *= 0.6;
            b *= 0.6;

            var i:Float = 0.2;
            var s:Float = 2;
            var p:Float = 0;

            var charCode:Int = CHARS.charCodeAt(ike % CHARS.length);

            glyph.makeCorners();
            glyph.set_shape(x, y, z, s, p);
            glyph.set_color(r, g, b);
            glyph.set_i(i);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(ike);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;
        var glyphWidth:Float = rectSize * 0.03;
        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }
}
