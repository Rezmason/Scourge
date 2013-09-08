package net.rezmason.scourge.textview;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class AlphabetBody extends Body {

    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
        TestStrings.SYMBOLS +
        TestStrings.WEIRD_SYMBOLS +
        TestStrings.BOX_SYMBOLS +
    '';

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {

        super(bufferUtil, glyphTexture, redrawHitAreas);

        var totalChars:Int = CHARS.length;
        var numRows:Int = Std.int(Math.ceil(Math.sqrt(totalChars)));
        var numCols:Int = Std.int(Math.ceil(totalChars / numRows));

        growTo(totalChars);

        catchMouseInRect = false;

        for (ike in 0...numGlyphs) {

            var glyph:Glyph = glyphs[ike];

            var col:Int = ike % numCols;
            var row:Int = Std.int(ike / numCols);

            var x:Float = ((col + 0.5) / numCols - 0.5);
            var y:Float = ((row + 0.5) / numRows    - 0.5);

            var charCode:Int = CHARS.charCodeAt(ike % CHARS.length);

            glyph.set_shape(x, y, 0, 1, 0);
            glyph.set_color(1, 1, 1);
            glyph.set_i(0.2);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(glyph.id | id << 16);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);
        setGlyphScale(0.05, 0.05 * stageWidth / stageHeight);

        transform.identity();
        transform.appendScale(1, -1, 1);
    }

    override public function interact(id:Int, interaction:Interaction):Void {
        var glyph:Glyph = glyphs[id];
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case ENTER: glyph.set_s(2);
                    case EXIT: glyph.set_s(1);
                    case MOUSE_DOWN: glyph.set_i(1);
                    case MOUSE_UP, DROP: glyph.set_i(0);
                    case CLICK: glyph.set_b(1 - glyph.get_b());
                    case _:
                }
            case KEYBOARD(type, key, char, shift, alt, ctrl):
        }
    }
}
