package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

class AlphabetModel extends Model {

    override function makeGlyphs():Void {
        super.makeGlyphs();

        for (ike in 0...26) {

            var x:Float = (ike + 0.5) / 26 - 0.5;
            var shape:Array<Float> = [
                x, 0, 0, 0, 0, 3, 0,
                x, 0, 0, 0, 1, 3, 0,
                x, 0, 0, 1, 1, 3, 0,
                x, 0, 0, 1, 0, 3, 0,
            ];

            var charCode:Int = 65 + ike;
            var fatChar:FatChar = new FatChar(charCode);
            var charUV = font.getCharCodeUVs(charCode);

            var color:Array<Float> = [
                1, 1, 1, charUV[3].u * glyphTexture.scaleX, charUV[3].v * glyphTexture.scaleY, 0.2,
                1, 1, 1, charUV[0].u * glyphTexture.scaleX, charUV[0].v * glyphTexture.scaleY, 0.2,
                1, 1, 1, charUV[1].u * glyphTexture.scaleX, charUV[1].v * glyphTexture.scaleY, 0.2,
                1, 1, 1, charUV[2].u * glyphTexture.scaleX, charUV[2].v * glyphTexture.scaleY, 0.2,
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
