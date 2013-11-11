package net.rezmason.scourge.textview;

import net.kawa.tween.easing.Back;
import net.kawa.tween.easing.Linear;

import haxe.Utf8;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class GlyphBody extends Body {

    static var COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ];
    inline static var TWEEN_LENGTH:Float = 1.5;
    inline static var WAIT_LENGTH:Float = 2;
    inline static var FADE_AMT:Float = 0;

    inline static var NUM_PHASES:Int = 3;
    static var periods:Array<Float> = [TWEEN_LENGTH, WAIT_LENGTH, TWEEN_LENGTH];
    static var tweenData:Array<Array<Float>> = [[0,1],[1,1],[1,0]];
    static var tweens:Array<Float->Float> = [Back.easeOut, Linear.easeIn, Back.easeIn];
    inline static var CHARS:String = 'ΩSCOURGE';
    var currentCharIndex:Int;

    var phaseTime:Float;
    var currentPhase:Int;
    var currentColor:Int;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {

        currentCharIndex = 0;
        currentPhase = 1;
        phaseTime = 0;
        currentColor = 0;

        super(bufferUtil, glyphTexture, redrawHitAreas);
        growTo(1);

        glyphs[0].set_char(Utf8.charCodeAt(CHARS, currentCharIndex), glyphTexture.font);
        colorGlyph(glyphs[0], COLORS[currentColor]);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);
        setGlyphScale(0.8, 0.8 * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
        transform.identity();
        transform.appendScale(1, -1, 1);
    }

    inline function colorGlyph(glyph:Glyph, color:Int, mult:Float = 1):Void {
        glyph.set_color(
            ((color >> 16 & 0xFF) / 0xFF) * mult,
            ((color >> 8  & 0xFF) / 0xFF) * mult,
            ((color >> 0  & 0xFF) / 0xFF) * mult
        );
    }

    override public function update(delta:Float):Void {
        phaseTime += delta;

        if (phaseTime > periods[currentPhase]) {
            phaseTime -= periods[currentPhase];
            currentPhase = (currentPhase + 1) % NUM_PHASES;
            if (currentPhase == 0) {
                currentCharIndex = (currentCharIndex + 1) % Utf8.length(CHARS);
                glyphs[0].set_char(Utf8.charCodeAt(CHARS, currentCharIndex), glyphTexture.font);
                currentColor = (currentColor + 1) % COLORS.length;
            }
        }

        var percent:Float = phaseTime / periods[currentPhase];

        var val:Float = tweens[currentPhase](percent);
        val = tweenData[currentPhase][0] * (1 - val) + tweenData[currentPhase][1] * val;
        glyphs[0].set_f(val * 0.5);
        colorGlyph(glyphs[0], COLORS[currentColor], val * (1 + FADE_AMT) - FADE_AMT);

        super.update(delta);
    }
}
