package net.rezmason.scourge.textview;

using net.rezmason.scourge.textview.GlyphUtils;

class FlatModel extends Model {

    override function makeGlyphs():Void {
        super.makeGlyphs();

        for (ike in 0...Constants.TOTAL_CHARS) {

            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = ike;
            glyphs.push(glyph);

            var col:Int = ike % Constants.COLUMNS;
            var row:Int = Std.int(ike / Constants.COLUMNS);

            var x:Float = ((col + 0.5) / Constants.COLUMNS - 0.5);
            var y:Float = ((row + 0.5) / Constants.ROWS    - 0.5);
            var z:Float = -1;
            z = 0;

            var charCode:Int = 65 + (ike % 26);

            var i:Float = 0.2;
            var s:Float = 1;
            var p:Float = 0;

            glyph.makeCorners();
            glyph.set_shape(x, y, z, s, p);
            glyph.set_color(1, 1, 1, i);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(ike);
        }
    }
}
