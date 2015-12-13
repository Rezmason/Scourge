package net.rezmason.hypertype.demo;

import net.rezmason.gl.GLTypes;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.FontManager;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.math.Vec3;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class MatrixDemo {

    inline static var CHARS = '012345678ABCDEFGHIJKLMNOPQRTabcdefghijklmnopqrstuvwxyz';

    public var body(default, null):Body;

    public function new():Void {
        var fontManager:FontManager = new Present(FontManager);
        body = new Body();
        body.glyphTexture = fontManager.getFontByName('matrix');
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
        body.glyphScale = 0.05;
    }

    public function update(delta:Float):Void {
        
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOVE, ENTER, EXIT: trace('$x $y');
                    case _:
                }
            case _:
        }
    }
}
