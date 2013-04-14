package net.rezmason.scourge.textview;

using net.rezmason.scourge.textview.GlyphUtils;

class AlphabetModel extends Model {

    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
        TestStrings.SYMBOLS +
        TestStrings.WEIRD_SYMBOLS +
        TestStrings.BOX_SYMBOLS +
    "";

    override function makeGlyphs():Void {
        super.makeGlyphs();

        var totalChars:Int = CHARS.length;
        var numRows:Int = Std.int(Math.ceil(Math.sqrt(totalChars)));
        var numCols:Int = Std.int(Math.ceil(totalChars / numRows));

        for (ike in 0...totalChars) {

            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = ike;
            glyphs.push(glyph);

            var col:Int = ike % numCols;
            var row:Int = Std.int(ike / numCols);

            var x:Float = ((col + 0.5) / numCols - 0.5);
            var y:Float = ((row + 0.5) / numRows    - 0.5);
            var z:Float = -1;
            z = 0;

            var i:Float = 0.2;
            var s:Float = 4;
            var p:Float = 0;

            var charCode:Int = CHARS.charCodeAt(ike % CHARS.length);

            var r:Float = Math.random() * 0.6 + 0.4;
            var g:Float = Math.random() * 0.6 + 0.4;
            var b:Float = Math.random() * 0.6 + 0.4;

            glyph.makeCorners();
            glyph.set_shape(x, y, z, s, p);
            glyph.set_color(r, g, b, i);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(ike);
        }
    }
}
