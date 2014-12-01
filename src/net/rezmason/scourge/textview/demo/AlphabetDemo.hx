package net.rezmason.scourge.textview.demo;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class AlphabetDemo {

    inline static var CHARS:String =
        Strings.ALPHANUMERICS +
        Strings.SYMBOLS +
        Strings.WEIRD_SYMBOLS +
        Strings.BOX_SYMBOLS +
    '';

    public var body(default, null):Body;

    public function new():Void {

        var totalChars:Int = CHARS.length;
        var numRows:Int = Std.int(Math.ceil(Math.sqrt(totalChars)));
        var numCols:Int = Std.int(Math.ceil(totalChars / numRows));

        body = new Body();
        body.growTo(totalChars);
        body.glyphScale = 0.025;
        body.transform.identity();
        body.transform.appendScale(1, -1, 1);
        body.interactionSignal.add(receiveInteraction);

        for (glyph in body.eachGlyph()) {

            var id:Int = glyph.id;
            var col:Int = id % numCols;
            var row:Int = Std.int(id / numCols);
            var x:Float = ((col + 0.5) / numCols - 0.5);
            var y:Float = ((row + 0.5) / numRows    - 0.5);
            var charCode:Int = Utf8.charCodeAt(CHARS, id % CHARS.length);

            glyph.set_xyz(x, y, 0);
            glyph.set_rgb(1, 1, 1);
            glyph.set_i(0.1);
            glyph.set_char(charCode);
            glyph.set_paint((glyph.id + 1) | body.id << 16); // necessary?
        }
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        if (id == 0) return;
        var glyph:Glyph = body.getGlyphByID(id - 1);
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
