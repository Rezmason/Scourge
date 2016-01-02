package net.rezmason.hypertype.demo;

import haxe.Utf8;
import net.rezmason.math.Vec3;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.core.GlyphTexture;

using net.rezmason.hypertype.core.GlyphUtils;

class AlphabetDemo {

    inline static var CHARS:String =
        Strings.ALPHANUMERICS +
        Strings.SYMBOLS +
        Strings.WEIRD_SYMBOLS +
        Strings.BOX_SYMBOLS +
    '';

    public var body(default, null):Body;

    public function new():Void {

        var totalChars:Int = Utf8.length(CHARS);
        var numRows:Int = Std.int(Math.ceil(Math.sqrt(totalChars)));
        var numCols:Int = Std.int(Math.ceil(totalChars / numRows));
        var white = new Vec3(1, 1, 1);

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

            glyph.SET({
                x: ((col + 0.5) / numCols - 0.5),
                y: ((row + 0.5) / numRows - 0.5),
                char: Utf8.charCodeAt(CHARS, id % CHARS.length),
                color: white,
                i:0.1,
                hitboxID: glyph.id + 1
            });
        }
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        if (id == 0) return;
        var glyph:Glyph = body.getGlyphByID(id - 1);
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case ENTER: glyph.set_w(0.2);
                    case EXIT: glyph.set_w(0);
                    case MOUSE_DOWN: glyph.set_p(0.01);
                    case MOUSE_UP, DROP: glyph.set_p(0);
                    case CLICK: glyph.set_s(3 - glyph.get_s());
                    case _:
                }
            case KEYBOARD(type, keyCode, modifier):
        }
    }
}
