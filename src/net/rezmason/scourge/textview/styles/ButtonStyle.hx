package net.rezmason.scourge.textview.styles;

import net.kawa.tween.easing.*;

import net.rezmason.scourge.textview.core.Interaction;

class ButtonStyle extends DynamicStyle {

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

    static var buttonFields:Array<String> = ['up', 'over', 'down', 'period'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic, ?mouseID:Int):Void {
        period = null;
        time = 0;
        easeFunc = Quad.easeInOut;
        fromIndex = 0;
        toIndex = 0;
        mouseIsOver = false;
        mouseIsDown = false;
        ratio = 1;
        super(name, basis, initValues, mouseID);
        if (mouseID == null) mouseID = 0;
        this.mouseID = mouseID;
        for (field in buttonFields) values[field] = Reflect.field(initValues, field);
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

    override public function interact(interaction:Interaction):Void {

        if (interaction == MOVE) return;

        var nextIndex:Int = toIndex;

        switch (interaction) {
            case ENTER: mouseIsOver = true;
            case EXIT: mouseIsOver = false;
            case DOWN: mouseIsDown = true;
            case UP, DROP: mouseIsDown = false;
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
        super.flatten();
    }
}
