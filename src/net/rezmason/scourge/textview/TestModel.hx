package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

using net.rezmason.scourge.textview.GlyphUtils;

class TestModel extends Model {

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
        TestStrings.SYMBOLS +
        TestStrings.WEIRD_SYMBOLS +
        TestStrings.BOX_SYMBOLS +
    "";

    override function makeGlyphs():Void {

        super.makeGlyphs();

        var numCols:Int = 50;
        var numRows:Int = 50;
        var totalChars:Int = numCols * numRows;

        for (ike in 0...totalChars) {

            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = ike;
            glyphs.push(glyph);

            var col:Int = ike % numCols;
            var row:Int = Std.int(ike / numCols);

            var x:Float = (col + 0.5) / numCols - 0.5;
            var y:Float = (row + 0.5) / numRows    - 0.5;
            var z:Float = -0.5;

            z *= Math.cos(row / numRows    * Math.PI * 2);
            z *= Math.cos(col / numCols * Math.PI * 2);

            var r:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var g:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var b:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            //*
            r = row / numRows;
            g = col / numCols;
            b = Math.cos(r) * Math.cos(g) * 0.5;
            /**/

            var i:Float = 0.2;
            var s:Float = 1;
            var p:Float = 0;

            var charCode:Int = CHARS.charCodeAt(ike % CHARS.length);

            glyph.makeCorners();
            glyph.set_shape(x, y, z, s, p);
            glyph.set_color(r, g, b, i);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(ike);
        }
    }
}
