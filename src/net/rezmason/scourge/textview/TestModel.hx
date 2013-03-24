package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

class TestModel extends Model {

    inline static var COLOR_RANGE:Int = 6;

    inline static var COLUMNS:Int = 50;
    inline static var ROWS:Int = 50;
    inline static var TOTAL_CHARS:Int = COLUMNS * ROWS;

    override function makeGlyphs():Void {
        super.makeGlyphs();

        for (ike in 0...TOTAL_CHARS) {

            var col:Int = ike % COLUMNS;
            var row:Int = Std.int(ike / COLUMNS);

            var x:Float = ((col + 0.5) / COLUMNS - 0.5);
            var y:Float = ((row + 0.5) / ROWS    - 0.5);
            var z:Float = -0.5;
            z *= Math.cos(row / ROWS    * Math.PI * 2);
            z *= Math.cos(col / COLUMNS * Math.PI * 2);

            var r:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var g:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var b:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            //*
            r = row / ROWS;
            g = col / COLUMNS;
            b = Math.cos(r) * Math.cos(g) * 0.5;
            /**/

            var charCode:Int = 65 + (ike % 26);

            var i:Float = 0.2;
            var s:Float = 1;
            var p:Float = 0;

            var fatChar:FatChar = new FatChar(charCode);
            var charUV = glyphTexture.font.getCharCodeUVs(charCode);

            var shape:Array<Float> = [
                x, y, z, 0, 0, s, p,
                x, y, z, 0, 1, s, p,
                x, y, z, 1, 1, s, p,
                x, y, z, 1, 0, s, p,
            ];

            var color:Array<Float> = [
                r, g, b, charUV[3].u, charUV[3].v, i,
                r, g, b, charUV[0].u, charUV[0].v, i,
                r, g, b, charUV[1].u, charUV[1].v, i,
                r, g, b, charUV[2].u, charUV[2].v, i,
            ];

            var glyph:Glyph = new Glyph();
            glyph.fatChar = fatChar;
            glyph.color = color;
            glyph.shape = shape;
            glyph.visible = true;
            glyph.id = ike;

            glyphs.push(glyph);
        }
    }
}
