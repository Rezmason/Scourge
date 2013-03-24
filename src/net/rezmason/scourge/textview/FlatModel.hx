package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

class FlatModel extends Model {

    override function makeGlyphs():Void {
        super.makeGlyphs();

        for (ike in 0...Constants.TOTAL_CHARS) {

            var col:Int = ike % Constants.COLUMNS;
            var row:Int = Std.int(ike / Constants.COLUMNS);

            var x:Float = ((col + 0.5) / Constants.COLUMNS - 0.5);
            var y:Float = ((row + 0.5) / Constants.ROWS    - 0.5);
            var z:Float = -1;
            z = 0;

            var charCode:Int = 65 + (ike % 26);
            var fatChar:FatChar = new FatChar(charCode);
            var charUV = glyphTexture.font.getCharCodeUVs(charCode);

            var i:Float = 0.2;
            var s:Float = 1;
            var p:Float = 0;

            var shape:Array<Float> = [
                x, y, z, 0, 0, s, p,
                x, y, z, 0, 1, s, p,
                x, y, z, 1, 1, s, p,
                x, y, z, 1, 0, s, p,
            ];

            var color:Array<Float> = [
                1, 1, 1, charUV[3].u, charUV[3].v, i,
                1, 1, 1, charUV[0].u, charUV[0].v, i,
                1, 1, 1, charUV[1].u, charUV[1].v, i,
                1, 1, 1, charUV[2].u, charUV[2].v, i,
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
