package net.rezmason.scourge.textview.text;

import net.kawa.tween.easing.Quad;

import net.rezmason.scourge.textview.core.Interaction;

class ButtonStyle extends Style {

    inline static var UP_FRAME:Int = 0;
    inline static var OVER_FRAME:Int = 1;
    inline static var DOWN_FRAME:Int = 2;

    var period:Null<Float>;
    var time:Float;
    var easeFunc:Float->Float;
    var fromIndex:Int;
    var toIndex:Int;
    var ratio:Float;

    var mouseIsOver:Bool;
    var mouseIsDown:Bool;

    static var buttonFields:Array<String> = ['up', 'over', 'down', 'period', 'ease'];

    public function new(dec:Dynamic, ?mouseID:Int):Void {
        period = null;
        time = 0;
        fromIndex = 0;
        toIndex = 0;
        mouseIsOver = false;
        mouseIsDown = false;
        ratio = 1;
        super(dec, mouseID);
        if (mouseID == null) mouseID = 0;
        this.mouseID = mouseID;
        for (field in buttonFields) values[field] = Reflect.field(dec, field);
    }

    override public function inherit(parent:Style):Void {
        inheritWithFields(parent, buttonFields);
        super.inherit(parent);
    }

    override public function updateGlyphs(delta:Float):Void {
        if (time < period) {
            time = time + delta;
            if (time > period) time = period;
            ratio = easeFunc(time / period);
            interpolateGlyphs(fromIndex, toIndex, ratio);
        }

        super.updateGlyphs(delta);
    }

    override public function receiveInteraction(type:MouseInteractionType):Void {

        if (type == MOVE) return;

        var nextIndex:Int = toIndex;

        switch (type) {
            case ENTER: mouseIsOver = true;
            case EXIT: mouseIsOver = false;
            case MOUSE_DOWN: mouseIsDown = true;
            case MOUSE_UP, DROP: mouseIsDown = false;
            case _:
        }

        if (mouseIsOver && mouseIsDown) nextIndex = DOWN_FRAME;
        else if (!mouseIsOver && !mouseIsDown) nextIndex = UP_FRAME;
        else nextIndex = OVER_FRAME;

        if (nextIndex != toIndex) {
            fromIndex = toIndex;
            toIndex = nextIndex;
            time = 0;
        }
    }

    override public function toString():String return '${super.toString()}, frames:${values["frames"]}';

    override public function connectBases(bases:Map<String, Style>):Void {
        var frames:Array<String> = [];
        frames[UP_FRAME] = values['up'];
        frames[OVER_FRAME] = values['over'];
        frames[DOWN_FRAME] = values['down'];
        if (frames[OVER_FRAME] == null) frames[OVER_FRAME] = frames[UP_FRAME];
        if (frames[DOWN_FRAME] == null) frames[DOWN_FRAME] = frames[OVER_FRAME];
        connectStates(bases, frames);
    }

    override public function flatten():Void {
        period = values['period'];
        if (period == null) period = 1;
        period = Math.abs(period);
        easeFunc = Style.easeLibrary[cast values['ease']];
        if (easeFunc == null) easeFunc = Quad.easeInOut;
        super.flatten();
    }
}
