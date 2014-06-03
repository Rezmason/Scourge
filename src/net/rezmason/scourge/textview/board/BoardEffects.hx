package net.rezmason.scourge.textview.board;

import net.rezmason.scourge.controller.ControllerTypes.NodeState;
import net.rezmason.scourge.textview.board.BoardTypes;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef BoardEffect = NodeTween->Float->Void;

class BoardEffects {

    static var EFFECTS_BY_STATE_CHANGE:Map<NodeState, Map<NodeState, Null<BoardEffect>>> = makeEffectMap();

    public static function getEffectForStateChange(state1:NodeState, state2:NodeState):BoardEffect {
        var effect:BoardEffect = null;
        if (state1 != null && state2 != null) {
            if (state1 == state2) {
                effect = animateLinear;
            } else if (EFFECTS_BY_STATE_CHANGE[state1] != null && EFFECTS_BY_STATE_CHANGE[state1][state2] != null) {
                effect = EFFECTS_BY_STATE_CHANGE[state1][state2];
            } else {
                trace('No effect for $state1-->$state2');
                effect = animateLinear;
            }
        } else {
            trace('Null state: $state1-->$state2');
            effect = animateLinear;
        }
        return animateLinear;
    }
    
    // ------- EFFECTS ------- //

    public static function animateLinear(tween:NodeTween, now:Float):Void {
        //trace('animateLinear ${getTimeFrac(tween.start, tween.duration, now)}');
        var frac:Float = getTimeFrac(tween.start, tween.duration, now);
        
        var topGlyph:Glyph = tween.view.topGlyph;
        var bottomGlyph:Glyph = tween.view.bottomGlyph;

        topGlyph.set_s(interp(tween.from.topSize, tween.to.topSize , frac));
        topGlyph.set_rgb(
            interp(tween.from.topColor.r, tween.to.topColor.r, frac),
            interp(tween.from.topColor.g, tween.to.topColor.g, frac),
            interp(tween.from.topColor.b, tween.to.topColor.b, frac)
        );
        
        if (tween.from.topChar == -1) {
            if (tween.view.topGlyph.get_char() != tween.to.topChar) {
                topGlyph.set_char(tween.to.topChar, tween.to.topFont);
            }
        } else if (tween.from.topChar != tween.to.topChar) {
            if (frac < 0.5) {
                topGlyph.set_f(interp(0.5, 0, frac * 2));
            } else {
                topGlyph.set_f(interp(0, 0.5, frac * 2 - 1));
                if (topGlyph.get_char() != tween.to.topChar) {
                    topGlyph.set_char(tween.to.topChar, tween.to.topFont);
                }
            }
        }

        bottomGlyph.set_s(interp(tween.from.bottomSize, tween.to.bottomSize , frac));
        bottomGlyph.set_rgb(
            interp(tween.from.bottomColor.r, tween.to.bottomColor.r, frac),
            interp(tween.from.bottomColor.g, tween.to.bottomColor.g, frac),
            interp(tween.from.bottomColor.b, tween.to.bottomColor.b, frac)
        );
        
        if (tween.from.bottomChar == -1) {
            if (tween.view.bottomGlyph.get_char() != tween.to.bottomChar) {
                bottomGlyph.set_char(tween.to.bottomChar, tween.to.bottomFont);
            }
        } else if (tween.from.bottomChar != tween.to.bottomChar) {
            if (frac < 0.5) {
                bottomGlyph.set_f(interp(0.5, 0, frac * 2));
            } else {
                bottomGlyph.set_f(interp(0, 0.5, frac * 2 - 1));
                if (bottomGlyph.get_char() != tween.to.bottomChar) {
                    bottomGlyph.set_char(tween.to.bottomChar, tween.to.bottomFont);
                }
            }
        }
    };

    public static function animateBodyEaten(tween:NodeTween, now:Float):Void {
        //trace('animateBodyEaten ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // Raise out, then drop in
        // change color linearly
    };

    public static function animateBodyKilled(tween:NodeTween, now:Float):Void {
        //trace('animateBodyKilled ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // View is suddenly no longer alive
        // turn pale, then lowers out
    };

    public static function animateCavityFadesOver(tween:NodeTween, now:Float):Void {
        //trace('animateCavityFadesOver ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // change color in-out
    };

    public static function animateCavityFadesIn(tween:NodeTween, now:Float):Void {
        //trace('animateCavityFadesIn ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // change color in
    };

    public static function animateCavityFadesOut(tween:NodeTween, now:Float):Void {
        //trace('animateCavityFadesOut ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // change color out
    };

    public static function animatePieceDropsDown(tween:NodeTween, now:Float):Void {
        //trace('animatePieceDropsDown ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // sudden
        // bounce down as white, then fade out to natural color
    };

    public static function animateHeadEaten(tween:NodeTween, now:Float):Void {
        //trace('animateHeadEaten ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // TODO - deserves special effect?
    };

    public static function animateHeadKilled(tween:NodeTween, now:Float):Void {
        //trace('animateHeadKilled ${getTimeFrac(tween.start, tween.duration, now)}');
        animateLinear(tween, now); // TEMPORARY
        // TODO - deserves special effect?
    };

    inline static function makeEffectMap():Map<NodeState, Map<NodeState, Null<BoardEffect>>> {
        return [
            Empty => [
                Cavity => animateCavityFadesIn, 
                Body => animatePieceDropsDown,
            ],
            Cavity => [
                Empty => animateCavityFadesOut, 
                Cavity => animateCavityFadesOver, 
                Body => animatePieceDropsDown,
            ],
            Wall => [
                Wall => animateLinear,
            ],
            Body => [
                Empty => animateBodyKilled, 
                Cavity => animateBodyKilled, 
                Body => animateBodyEaten,
            ],
            Head => [
                Empty => animateHeadKilled, 
                Cavity => animateHeadKilled, 
                Body => animateHeadEaten,
            ],
        ];
    }

    inline static function getTimeFrac(start:Float, duration:Float, now:Float):Float return (now - start) / duration;

    inline static function interp(val1:Float, val2:Float, frac:Float):Float return val1 * (1 - frac) + val2 * frac;
}

