package net.rezmason.scourge.textview.demo;

import net.kawa.tween.easing.Quint;
import net.kawa.tween.easing.Linear;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class GlyphDemo {

    static var COLORS:Array<Color> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Colors.fromHex);
    inline static var TWEEN_LENGTH:Float = 0.25;
    inline static var WAIT_LENGTH:Float = 0.5;
    inline static var FADE_AMT:Float = 0;

    inline static var NUM_PHASES:Int = 3;
    static var periods:Array<Float> = [TWEEN_LENGTH, WAIT_LENGTH, TWEEN_LENGTH];
    static var tweenData:Array<Array<Float>> = [[0,1],[1,1],[1,0]];
    static var tweens:Array<Float->Float> = [Quint.easeOut, Linear.easeIn, Quint.easeIn];
    inline static var CHARS:String = 'ΩSCOURGE';

    public var body(default, null):Body;
    var currentCharIndex:Int;
    var phaseTime:Float;
    var currentPhase:Int;
    var currentColor:Int;
    var mouseIsDown:Bool;
    var glyph:Glyph;

    public function new():Void {

        currentCharIndex = 0;
        currentPhase = 1;
        phaseTime = 0;
        currentColor = 0;
        mouseIsDown = false;

        body = new Body();
        body.interactionSignal.add(receiveInteraction);
        body.updateSignal.add(update);
        body.glyphScale = 0.4;
        body.growTo(1);

        glyph = body.getGlyphByID(0);
        glyph.set_char(Utf8.charCodeAt(CHARS, currentCharIndex));
        glyph.set_color(COLORS[currentColor]);
    }

    function update(delta:Float):Void {
        phaseTime += delta * (mouseIsDown ? 0.2 : 1);

        if (phaseTime > periods[currentPhase]) {
            phaseTime -= periods[currentPhase];
            currentPhase = (currentPhase + 1) % NUM_PHASES;
            if (currentPhase == 0) {
                currentCharIndex = (currentCharIndex + 1) % Utf8.length(CHARS);
                glyph.set_char(Utf8.charCodeAt(CHARS, currentCharIndex));
                currentColor = (currentColor + 1) % COLORS.length;
            }
        }

        var percent:Float = phaseTime / periods[currentPhase];

        var val:Float = tweens[currentPhase](percent);
        val = tweenData[currentPhase][0] * (1 - val) + tweenData[currentPhase][1] * val;
        glyph.set_f(val * 0.5);
        glyph.set_color(Colors.mult(COLORS[currentColor], val * (1 + FADE_AMT) - FADE_AMT));
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
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
