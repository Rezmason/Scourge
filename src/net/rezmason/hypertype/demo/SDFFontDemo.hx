package net.rezmason.hypertype.demo;

import haxe.Utf8;
import motion.easing.Linear;
import motion.easing.Quint;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.math.Vec4;

using net.rezmason.hypertype.core.GlyphUtils;

class SDFFontDemo extends Demo {

    static var COLORS:Array<Vec4> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Vec4.fromHex);
    inline static var TWEEN_LENGTH:Float = 0.25;
    inline static var WAIT_LENGTH:Float = 0.5;

    inline static var NUM_PHASES:Int = 3;
    static var periods:Array<Float> = [TWEEN_LENGTH, WAIT_LENGTH, TWEEN_LENGTH];
    static var tweenData:Array<Array<Float>> = [[0,1],[1,1],[1,0]];
    static var tweens:Array<Float->Float> = [Quint.easeOut.calculate, Linear.easeNone.calculate, Quint.easeIn.calculate];
    inline static var CHARS:String = 'ΩSCOURGE';

    var glyph:Glyph;
    var currentCharIndex = 0;
    var currentPhase = 1;
    var currentColor = 0;
    var mouseIsDown = false;

    public function new():Void {
        super();
        body.glyphScale = 0.6;
        body.growTo(1);

        glyph = body.getGlyphByID(0);
        glyph.set_char(Utf8.charCodeAt(CHARS, currentCharIndex));
        glyph.set_color(COLORS[currentColor]);
    }

    override function update(delta:Float):Void {
        time += delta * (mouseIsDown ? 0.2 : 1);

        if (time > periods[currentPhase]) {
            time -= periods[currentPhase];
            currentPhase = (currentPhase + 1) % NUM_PHASES;
            if (currentPhase == 0) {
                currentCharIndex = (currentCharIndex + 1) % Utf8.length(CHARS);
                glyph.set_char(Utf8.charCodeAt(CHARS, currentCharIndex));
                currentColor = (currentColor + 1) % COLORS.length;
            }
        }

        var percent:Float = time / periods[currentPhase];

        var val:Float = tweens[currentPhase](percent);
        val = tweenData[currentPhase][0] * (1 - val) + tweenData[currentPhase][1] * val;

        glyph.set_w(val * 0.1 + (1 - val) * -0.7);
        glyph.set_color(COLORS[currentColor]);
    }

    override function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOUSE_DOWN: mouseIsDown = true;
                    case MOUSE_UP: mouseIsDown = false;
                    case _:
                }
            case _:
        }
    }
}
