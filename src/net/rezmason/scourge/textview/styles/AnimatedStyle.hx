package net.rezmason.scourge.textview.styles;

import net.kawa.tween.easing.*;

class AnimatedStyle extends DynamicStyle {

    var animationValues:Map<String, Dynamic>;

    var period:Null<Float>;
    var phase:Null<Float>;
    var time:Float;

    static var animationFields:Array<String> = ['period', 'phase', 'frames'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic):Void {
        period = null;
        phase = null;
        animationValues = new Map<String, Dynamic>();
        for (field in animationFields) animationValues.set(field, Reflect.field(initValues, field));
        time = 0;
        super(name, basis, initValues);
    }

    override public function inherit(parent:Style):Void {
        super.inherit(parent);
        if (Std.is(parent, AnimatedStyle)) inheritAnimation(cast parent);
    }

    function inheritAnimation(parent:AnimatedStyle):Void {
        if (parent == null) return;

        for (field in animationFields) {
            if (animationValues[field] == null) {
                animationValues.set(field, parent.animationValues[field]);
            }
        }
    }

    override public function updateGlyphs(delta:Float):Void {

        if (states != null) {
            time = (time + delta) % period;

            var playhead:Float = time / period * stateStyles.length;

            var fromIndex:Int = Std.int(Math.floor(playhead));
            var toIndex:Int = Std.int(Math.ceil(playhead) % stateStyles.length);
            var ratio:Float = easeFunc((playhead + phase) % 1);

            for (key in states.keys()) {
                var fieldValues:Array<Float> = states[key];
                values.set(key, fieldValues[fromIndex] * (1 - ratio) + fieldValues[toIndex] * ratio);
            }
        }

        super.updateGlyphs(delta);
    }

    override public function toString():String return '${super.toString()}, frames:${animationValues.get("frames")}';

    override public function connectBases(bases:Map<String, Style>):Void {
        var frames:Array<String> = animationValues.get("frames");
        if (frames == null) frames = [];
        connectStates(bases, frames);
    }

    override public function flatten():Void {

        period = animationValues['period'];
        phase = animationValues['phase'];

        if (period == null) period = 1;
        if (phase  == null) phase  = 0;

        period = Math.abs(period);
        phase = ((phase % period) + period) % period;

        super.flatten();
    }
}
