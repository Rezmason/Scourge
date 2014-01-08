package net.rezmason.scourge.textview.text;

import net.kawa.tween.easing.Quad;

import net.rezmason.scourge.textview.core.Interaction;

class InputStyle extends DynamicStyle {

    inline static var HINT_FRAME:Int = 0;
    inline static var VALID_FRAME:Int = 1;
    inline static var INVALID_FRAME:Int = 2;

    var period:Null<Float>;
    var time:Float;
    var easeFunc:Float->Float;
    var fromIndex:Int;
    var toIndex:Int;
    var ratio:Float;

    static var inputFields:Array<String> = ['hint', 'valid', 'invalid', 'period', 'ease'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic, ?mouseID:Int):Void {
        period = null;
        time = 0;
        fromIndex = 0;
        toIndex = 0;
        ratio = 1;
        super(name, basis, initValues, mouseID);
        if (mouseID == null) mouseID = 0;
        this.mouseID = mouseID;
        for (field in inputFields) values[field] = Reflect.field(initValues, field);
    }

    override public function inherit(parent:Style):Void {
        inheritWithFields(parent, inputFields);
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
        super.receiveInteraction(type);
        // TODO
    }

    override public function toString():String return '${super.toString()}, frames:${values["frames"]}';

    override public function connectBases(bases:Map<String, Style>):Void {
        var frames:Array<String> = [];
        frames[HINT_FRAME] = values['hint'];
        frames[VALID_FRAME] = values['valid'];
        frames[INVALID_FRAME] = values['invalid'];
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
