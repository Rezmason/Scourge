package net.rezmason.scourge.textview.text;

import motion.easing.Quad;

import net.rezmason.scourge.textview.core.MouseInteractionType;

typedef ButtonSpanState = {
    var time:Float;
    var fromIndex:Int;
    var toIndex:Int;
    var ratio:Float;
    var mouseIsOver:Bool;
    var mouseIsDown:Bool;
}

class ButtonStyle extends Style {

    inline static var UP_FRAME:Int = 0;
    inline static var OVER_FRAME:Int = 1;
    inline static var DOWN_FRAME:Int = 2;

    var period:Null<Float>;
    var easeFunc:Float->Float;

    static var buttonFields:Array<String> = ['up', 'over', 'down', 'period', 'ease'];

    public function new(dec:Dynamic):Void {
        period = 0;
        super(dec);
        isInteractive = true;
        for (field in buttonFields) values[field] = Reflect.field(dec, field);
    }

    override public function connectSpan(span:Span):Void {
        span.state = {time:0, fromIndex:0, toIndex:0, mouseIsOver:false, mouseIsDown:false, ratio:1};
        super.connectSpan(span);
    }

    override public function inherit(parent:Style):Void {
        inheritWithFields(parent, buttonFields);
        super.inherit(parent);
    }

    override public function update(spans:Array<Span>, delta:Float, force:Bool):Void {
        for (span in spans) updateSpan(span, delta);
    }

    override public function updateSpan(span:Span, delta:Float):Void {
        var state:ButtonSpanState = cast span.state;

        if (state.time < period || period == 0) {
            state.time = state.time + delta;
            if (state.time > period) state.time = period;
            state.ratio = easeFunc(state.time / period);
            if (period == 0) state.ratio = 1;
            interpolateSpan(span, state.fromIndex, state.toIndex, state.ratio);
        }

        super.updateSpan(span, delta);
    }

    override public function handleSpanInteraction(span:Span, type:MouseInteractionType):Void {
        var state:ButtonSpanState = cast span.state;

        if (type == MOVE) return;

        var nextIndex:Int = state.toIndex;

        switch (type) {
            case ENTER: state.mouseIsOver = true;
            case EXIT: state.mouseIsOver = false;
            case MOUSE_DOWN: state.mouseIsDown = true;
            case MOUSE_UP, DROP: state.mouseIsDown = false;
            case _:
        }

        if (state.mouseIsOver && state.mouseIsDown) nextIndex = DOWN_FRAME;
        else if (!state.mouseIsOver && !state.mouseIsDown) nextIndex = UP_FRAME;
        else nextIndex = OVER_FRAME;

        if (nextIndex != state.toIndex) {
            state.fromIndex = state.toIndex;
            state.toIndex = nextIndex;
            state.time = 0;
        }
    }

    override public function toString():String return '${super.toString()}, frames:${values["frames"]}';

    override public function connectBases(bases:Map<String, Style>):Void {
        var frames:Array<String> = [];
        frames[UP_FRAME] = values['up'];
        frames[OVER_FRAME] = values['over'];
        frames[DOWN_FRAME] = values['down'];
        if (frames[UP_FRAME] == null) frames[UP_FRAME] = '';
        if (frames[OVER_FRAME] == null) frames[OVER_FRAME] = frames[UP_FRAME];
        if (frames[DOWN_FRAME] == null) frames[DOWN_FRAME] = frames[OVER_FRAME];
        connectStates(bases, frames);
    }

    override public function flatten():Void {
        period = values['period'];
        if (period == null) period = 1;
        period = Math.abs(period);
        easeFunc = Quad.easeInOut.calculate;
        super.flatten();
    }
}
