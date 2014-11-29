package net.rezmason.scourge.textview.demo;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class AlphabetBody extends Body {

    inline static var CHARS:String =
        Strings.ALPHANUMERICS +
        Strings.SYMBOLS +
        Strings.WEIRD_SYMBOLS +
        Strings.BOX_SYMBOLS +
    '';

    public function new():Void {

        super();

        var totalChars:Int = CHARS.length;
        var numRows:Int = Std.int(Math.ceil(Math.sqrt(totalChars)));
        var numCols:Int = Std.int(Math.ceil(totalChars / numRows));

        growTo(totalChars);

        for (ike in 0...numGlyphs) {

            var glyph:Glyph = glyphs[ike];

            var col:Int = ike % numCols;
            var row:Int = Std.int(ike / numCols);

            var x:Float = ((col + 0.5) / numCols - 0.5);
            var y:Float = ((row + 0.5) / numRows    - 0.5);

            var charCode:Int = Utf8.charCodeAt(CHARS, ike % CHARS.length);

            glyph.set_xyz(x, y, 0);
            glyph.set_rgb(1, 1, 1);
            glyph.set_i(0.1);
            glyph.set_font(glyphTexture.font);
            glyph.set_char(charCode);
            glyph.set_paint((glyph.id + 1) | id << 16);
        }
    }

    override public function resize(stageWidth:Int, stageHeight:Int):Void {
        super.resize(stageWidth, stageHeight);
        setGlyphScale(0.025, 0.025 * glyphTexture.font.glyphRatio * stageWidth / stageHeight);

        transform.identity();
        transform.appendScale(1, -1, 1);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
        if (id == 0) return;
        var glyph:Glyph = glyphs[id - 1];
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case ENTER: glyph.set_f(0.7);
                    case EXIT: glyph.set_f(0.5);
                    case MOUSE_DOWN: glyph.set_p(0.01);
                    case MOUSE_UP, DROP: glyph.set_p(0);
                    case CLICK: glyph.set_s(3 - glyph.get_s());
                    case _:
                }
            case KEYBOARD(type, key, char, shift, alt, ctrl):
        }
    }
}
