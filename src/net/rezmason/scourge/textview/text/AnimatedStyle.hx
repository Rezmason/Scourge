package net.rezmason.scourge.textview.text;

import net.kawa.tween.easing.*;

class AnimatedStyle extends DynamicStyle {

    public var time(default, set):Float;
    var period:Null<Float>;
    var phase:Null<Float>;
    var easeFunc:Float->Float;
    var playing:Bool;

    static var animationFields:Array<String> = ['period', 'phase', 'frames'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic, ?mouseID:Int):Void {
        period = null;
        phase = null;
        time = 0;
        playing = true;
        easeFunc = Quad.easeInOut;
        super(name, basis, initValues, mouseID);
        for (field in animationFields) values[field] = Reflect.field(initValues, field);
    }

    public function start(time:Float = 0):Void {
        this.time = time % period;
        playing = true;
    }

    public function stop():Void {
        this.time = 0;
        playing = false;
    }

    override public function inherit(parent:Style):Void {
        inheritWithFields(parent, animationFields);
        super.inherit(parent);
    }

    override public function updateGlyphs(delta:Float):Void {

        if (playing) {
            time = (time + delta) % period;
        }

        var numFrames:Int = stateStyles.length;
        if (numFrames < 1) numFrames = 1;

        var playhead:Float = time / period * numFrames;
        var fromIndex:Int = Std.int(Math.floor(playhead));
        var toIndex:Int = Std.int(Math.ceil(playhead) % numFrames);
        var ratio:Float = easeFunc((playhead + phase) % 1);

        interpolateGlyphs(fromIndex, toIndex, ratio);

        super.updateGlyphs(delta);
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

        super.flatten();
    }

    inline function set_time(value:Float):Float {
        if (Math.isNaN(value)) value = 0;
        time = value;
        return time;
    }
}
