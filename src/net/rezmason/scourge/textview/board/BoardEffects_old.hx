package net.rezmason.scourge.textview.board;

import net.rezmason.scourge.controller.ControllerTypes.NodeState;
import net.rezmason.scourge.textview.board.BoardTypes;
import net.rezmason.scourge.textview.ColorPalette;

import net.kawa.tween.easing.*;

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
        //arr.push(makeTween(view, cause, start, duration, from, to)); // TEMPORARY
        // Raise out, then drop in
        // change color linearly

        var raisedProps:NodeProps = cloneProps(to);
        raisedProps.top.color = {
            r:raisedProps.top.color.r * 0.2 + 0.8,
            g:raisedProps.top.color.g * 0.2 + 0.8,
            b:raisedProps.top.color.b * 0.2 + 0.8,
        };
        raisedProps.top.char = from.top.char;
        raisedProps.top.size = 1.2;
        raisedProps.waveMult = 0;
        // raisedProps.top.size = 1.2;
        raisedProps.top.thickness = 0.7;
        arr.push(makeTween(view, cause, start, duration * 0.5, from, raisedProps, Quad.easeIn));
        arr.push(makeTween(view, cause, start + duration * 0.5, duration * 0.5, raisedProps, to, Quad.easeIn));
        
    };

    static function animateBodyKilled(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        var mid:NodeProps = cloneProps(from);
        mid.top.color = {
            r:mid.top.color.r * 0.5 + 0.4,
            g:mid.top.color.g * 0.5 + 0.4,
            b:mid.top.color.b * 0.5 + 0.4,
        };
        mid.waveMult = 0;
        mid.bottom = to.bottom;
        to.top.thickness = 0.8;
        to.top.char = from.top.char;
        //to.top.pos.z = view.pos.z + 0.05;
        to.top.size = 2;
        arr.push(makeTween(view, cause, start, duration * 0.7, from, mid, Quad.easeInOut));
        arr.push(makeTween(view, cause, start + 0.7 * duration, duration * 0.3, mid, to, Linear.easeIn));
    };

    static function animateCavityFade(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        var mid:NodeProps = cloneProps(to);
        //mid.bottom.size = to.bottom.size * 1.25;
        arr.push(makeTween(view, cause, start, duration * 0.5, from, mid, Circ.easeOut));
        arr.push(makeTween(view, cause, start + 0.5 * duration, duration * 0.5, mid, to, Circ.easeIn));
    };

    static function animatePieceDropsDown(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        from.top.pos.z = view.pos.z - 0.5;
        from.top.pos.x = view.pos.x;
        from.top.pos.y = view.pos.y;
        
        from.top.color = ColorPalette.BLACK;
        from.top.size = 1.2;
        from.top.thickness = 0.7;
        from.top.stretch = 1;
        from.top.char = '•'.code();
        // from.top.char = to.top.char;
        var hotProps:NodeProps = cloneProps(to);
        hotProps.top.pos.x = view.pos.x;
        hotProps.top.pos.y = view.pos.y;
        hotProps.top.color = {
            r:hotProps.top.color.r * 0.4 + 0.6,
            g:hotProps.top.color.g * 0.4 + 0.6,
            b:hotProps.top.color.b * 0.4 + 0.6,
        };
        hotProps.top.char = from.top.char;
        hotProps.top.stretch = 1;
        hotProps.waveMult = 0;
        hotProps.top.size = 1.2;
        hotProps.top.thickness = 0.7;
        hotProps.bottom = from.bottom;
        arr.push(makeTween(view, cause, start, duration * 0.6, from, hotProps, Quart.easeInOut));
        arr.push(makeTween(view, cause, start + duration * 0.6, duration * 0.4, hotProps, to, Quad.easeInOut));
    };

    static function animateHeadEaten(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        animateBodyEaten(view, cause, start, duration, from, to, arr);
    };

    static function animateHeadKilled(view:NodeView, cause:String, start:Float, duration:Float, from:NodeProps, to:NodeProps, arr:Array<NodeTween>):Void {
        animateBodyKilled(view, cause, start, duration, from, to, arr);
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
            pos:clonePos(glyphProps.pos), 
            color:copiedColor, 
            thickness:glyphProps.thickness,
            stretch:glyphProps.stretch,
        };
    }

    inline static function clonePos(pos:XYZ):XYZ return {x:pos.x, y:pos.y, z:pos.z};
}

