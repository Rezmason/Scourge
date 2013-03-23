package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

class FlatModel extends Model {

    override function makeGlyphs():Void {
        super.makeGlyphs();

        for (ike in 0...Constants.NUM_CHARS) {

            var col:Int = ike % Constants.NUM_COLUMNS;
            var row:Int = Std.int(ike / Constants.NUM_COLUMNS);

            var x:Float = ((col + 0.5) / Constants.NUM_COLUMNS - 0.5);
            var y:Float = ((row + 0.5) / Constants.NUM_ROWS    - 0.5);
            var z:Float = -1;
            z = 0;

            var charCode:Int = 65 + (ike % 26);
            var fatChar:FatChar = new FatChar(charCode);
            var charUV = font.getCharCodeUVs(charCode);

            var i:Float = 0.2;
            var s:Float = 1;

            var geom:Array<Float> = [
                x, y, z, 0, 0, s,
                x, y, z, 0, 1, s,
                x, y, z, 1, 1, s,
                x, y, z, 1, 0, s,
            ];

            var color:Array<Float> = [
                1, 1, 1, charUV[3].u * glyphTexture.scaleX, charUV[3].v * glyphTexture.scaleY, i,
                1, 1, 1, charUV[0].u * glyphTexture.scaleX, charUV[0].v * glyphTexture.scaleY, i,
                1, 1, 1, charUV[1].u * glyphTexture.scaleX, charUV[1].v * glyphTexture.scaleY, i,
                1, 1, 1, charUV[2].u * glyphTexture.scaleX, charUV[2].v * glyphTexture.scaleY, i,
            ];

            var glyph:Glyph = new Glyph();
            glyph.fatChar = fatChar;
            glyph.color = color;
            glyph.shape = geom;
            glyph.visible = true;
            glyph.id = ike;

            glyphs.push(glyph);
        }
    }
}
