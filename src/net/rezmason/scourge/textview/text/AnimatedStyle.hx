package net.rezmason.scourge.textview.text;

import motion.easing.*;

typedef AnimatedSpanState = {
    var time:Float;
    var playing:Bool;
}

class AnimatedStyle extends Style {

    var period:Null<Float>;
    var phase:Null<Float>;
    var easeFunc:Float->Float;
    var time:Float;
    var persistentState:AnimatedSpanState;

    static var animationFields:Array<String> = ['period', 'phase', 'frames', 'ease', 'persist'];

    public function new(dec:Dynamic):Void {
        period = null;
        phase = null;
        time = 0;
        super(dec);
        for (field in animationFields) values[field] = Reflect.field(dec, field);
    }

    public function startSpan(span:Span, time:Float = 0):Void {
        var state:AnimatedSpanState = persistentState;
        if (state == null) state =  cast span.state;
        state.time = time % period;
        state.playing = true;
    }

    public function stopSpan(span:Span):Void {
        var state:AnimatedSpanState = persistentState;
        if (state == null) state =  cast span.state;
        state.time = 0;
        state.playing = false;
    }

    override public function connectSpan(span:Span):Void {
        span.state = {time:0, playing:true};
        super.connectSpan(span);
    }

    override public function inherit(parent:Style):Void {
        inheritWithFields(parent, animationFields);
        super.inherit(parent);
    }

    override public function update(spans:Array<Span>, delta:Float, force:Bool):Void {
        if (persistentState != null) updateState(persistentState, delta);
        for (span in spans) updateSpan(span, delta);
    }

    override public function updateSpan(span:Span, delta:Float):Void {

        var state:AnimatedSpanState = persistentState;
        if (state == null) {
            state = cast span.state;
            updateState(cast span.state, delta);
        }

        var numFrames:Int = stateStyles.length;
        if (numFrames < 1) numFrames = 1;

        var playhead:Float = state.time / period * numFrames;
        var fromIndex:Int = Std.int(Math.floor(playhead));
        var toIndex:Int = Std.int(Math.ceil(playhead) % numFrames);
        var ratio:Float = easeFunc((playhead + phase) % 1);

        interpolateSpan(span, fromIndex, toIndex, ratio);

        super.updateSpan(span, delta);
    }

    inline function updateState(state:AnimatedSpanState, delta:Float):Void {
        if (state.playing) state.time = (state.time + delta) % period;
    }

    override public function toString():String return '${super.toString()}, frames:${values["frames"]}';

    override public function connectBases(bases:Map<String, Style>):Void {
        var frames:Array<String> = values["frames"];
        if (frames == null) frames = [];
        connectStates(bases, frames);
    }

    override public function flatten():Void {
        period = values['period'];
        phase = values['phase'];

        if (period == null) period = 1;
        if (phase  == null) phase  = 0;

        period = Math.abs(period);
        phase = ((phase % period) + period) % period;

        easeFunc = Quad.easeInOut.calculate;

        if (values['persist'] == 'true') persistentState = {time:0, playing:true};

        super.flatten();
    }
}
