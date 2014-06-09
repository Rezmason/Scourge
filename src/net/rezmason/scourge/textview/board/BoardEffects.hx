package net.rezmason.scourge.textview.board;

import net.rezmason.scourge.controller.ControllerTypes.NodeState;
import net.rezmason.scourge.textview.board.BoardTypes;
import net.rezmason.scourge.textview.core.Glyph;

import net.kawa.tween.easing.*;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.CharCode;

typedef BoardEffect = NodeView->String->Float->Float->NodeProps->NodeProps->Array<NodeTween>->Void;

class BoardEffects {

    static var EFFECTS_BY_STATE_CHANGE:Map<NodeState, Map<NodeState, Null<BoardEffect>>> = makeEffectMap();

    public static function getEffectForStateChange(state1:NodeState, state2:NodeState):BoardEffect {
        var effect:BoardEffect = null;
        if (state1 != null && state2 != null) {
            if (EFFECTS_BY_STATE_CHANGE[state1] != null && EFFECTS_BY_STATE_CHANGE[state1][state2] != null) {
                effect = EFFECTS_BY_STATE_CHANGE[state1][state2];
            } else {
                if (state1 != state2) trace('No effect for $state1-->$state2');
                effect = animateLinear;
            }
        } else {
            trace('Null state: $state1-->$state2');
            effect = animateLinear;
        }
        return effect;
    }
    
    // ------- EFFECTS ------- //

    public static function animateLinear(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        arr.push(makeTween(view, cause, start, duration, from, to));
    };

    static function animateBodyEaten(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        arr.push(makeTween(view, cause, start, duration, from, to)); // TEMPORARY
        // Raise out, then drop in
        // change color linearly
    };

    static function animateBodyKilled(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        var mid:NodeProps = cloneProps(from);
        mid.top.color.r = (mid.top.color.r + 0.75) / 2;
        mid.top.color.g = (mid.top.color.g + 0.75) / 2;
        mid.top.color.b = (mid.top.color.b + 0.75) / 2;
        mid.waveMult = 0;
        arr.push(makeTween(view, cause, start, duration * 0.5, from, mid, Quad.easeInOut));
        arr.push(makeTween(view, cause, start + 0.5 * duration, duration * 0.5, mid, to, Quad.easeIn));
    };

    static function animateCavityFade(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        var mid:NodeProps = cloneProps(to);
        //mid.bottom.size = to.bottom.size * 1.25;
        arr.push(makeTween(view, cause, start, duration * 0.5, from, mid, Circ.easeOut));
        arr.push(makeTween(view, cause, start + 0.5 * duration, duration * 0.5, mid, to, Circ.easeIn));
    };

    static function animatePieceDropsDown(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        from.top.z = view.pos.z - 0.5;
        from.top.color.r = 0;
        from.top.color.g = 0;
        from.top.color.b = 0;
        from.top.size = 2;
        from.top.thickness = 0.7;
        from.top.char = '•'.code();
        var hotProps:NodeProps = cloneProps(to);
        hotProps.top.color.r = 1;
        hotProps.top.color.g = 1;
        hotProps.top.color.b = 1;
        hotProps.top.char = from.top.char;
        hotProps.top.size = 1;
        hotProps.waveMult = 0;
        // hotProps.top.size = 1.2;
        hotProps.top.thickness = 0.7;
        arr.push(makeTween(view, cause, start, duration * 0.3, from, hotProps, Quad.easeIn));
        arr.push(makeTween(view, cause, start + duration * 0.3, duration * 0.7, hotProps, to, Quad.easeIn));
    };

    static function animateHeadEaten(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        arr.push(makeTween(view, cause, start, duration, from, to)); // TEMPORARY
        // TODO - deserves special effect?
    };

    static function animateHeadKilled(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        arr.push(makeTween(view, cause, start, duration, from, to)); // TEMPORARY
        // TODO - deserves special effect?
    };

    inline static function makeTween(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, ease:Float->Float = null):NodeTween {
        return {view:view, cause:cause, from:from, to:to, start:start, duration:duration, ease:ease};
    }

    inline static function makeEffectMap():Map<NodeState, Map<NodeState, Null<BoardEffect>>> {
        return [
            Empty => [
                Cavity => animateCavityFade, 
                Body => animatePieceDropsDown,
            ],
            Cavity => [
                Empty => animateCavityFade, 
                Cavity => animateCavityFade, 
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

    inline static function cloneProps(props:NodeProps):NodeProps {
        return {
            top:cloneGlyphProps(props.top), 
            bottom:cloneGlyphProps(props.bottom), 
            waveMult:props.waveMult,
        };
    }

    inline static function cloneGlyphProps(glyphProps:NodeGlyphProps):NodeGlyphProps {
        var copiedColor:Color = {
            r:glyphProps.color.r,
            g:glyphProps.color.g,
            b:glyphProps.color.b,
        };
        return {
            char:glyphProps.char, 
            size:glyphProps.size, 
            z:glyphProps.z, 
            color:copiedColor, 
            thickness:glyphProps.thickness,
        };
    }
}

