package net.rezmason.scourge.textview.styles;

import net.kawa.tween.easing.*;

using Reflect;
using Type;

class AnimatedStyle extends Style {

    var animationValues:Map<String, Dynamic>;

    var period:Null<Float>;
    var phase:Null<Float>;
    var frameStyles:Array<Style>;
    var timeline:Map<String, Array<Float>>;
    var time:Float;
    var easeFunc:Float->Float;

    static var animationFields:Array<String> = ['period', 'phase', 'frames'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic):Void {
        period = null;
        phase = null;
        timeline = null;
        animationValues = new Map<String, Dynamic>();
        for (field in animationFields) animationValues.set(field, initValues.field(field));
        frameStyles = [];
        time = 0;
        easeFunc = Quad.easeInOut;
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

        if (timeline != null) {
            time = (time + delta) % period;

            var playhead:Float = time / period * frameStyles.length;

            var fromIndex:Int = Std.int(Math.floor(playhead));
            var toIndex:Int = Std.int(Math.ceil(playhead) % frameStyles.length);
            var ratio:Float = easeFunc((playhead + phase) % 1);

            for (key in timeline.keys()) {
                var fieldValues:Array<Float> = timeline[key];
                values.set(key, fieldValues[fromIndex] * (1 - ratio) + fieldValues[toIndex] * ratio);
            }
        }

        super.updateGlyphs(delta);
    }

    override public function toString():String return '${super.toString()}, frames:${animationValues.get("frames")}';

    override public function connectBases(bases:Map<String, Style>):Void {
        var frames:Array<String> = animationValues.get("frames");
        if (frames == null) frames = [];

        for (ike in 0...frames.length) {
            var frameStyle:Style = new Style('${name}_$ike');
            frameStyle.inherit(bases[frames[ike]]);
            frameStyle.inherit(bases[""]);
            frameStyles.push(frameStyle);
        }
    }

    override public function flatten():Void {

        period = animationValues['period'];
        phase = animationValues['phase'];

        if (period == null) period = 1;
        if (phase  == null) phase  = 0;

        period = Math.abs(period);
        phase = ((phase % period) + period) % period;

        timeline = new Map();
        var timelineEmpty:Bool = true;

        for (field in Style.styleFields) {
            var animateField:Bool = false;
            var fieldValues:Array<Float> = [];
            var firstValue:Null<Float> = null;

            if (values[field] == null) {
                firstValue = frameStyles[0].values[field];
                for (frame in frameStyles) {
                    if (!animateField && firstValue != frame.values[field]) animateField = true;
                    fieldValues.push(frame.values[field]);
                }
            }

            if (animateField) {
                timeline.set(field, fieldValues);
                timelineEmpty = false;
            } else if (values[field] == null) {
                values.set(field, firstValue);
            }
        }

        if (timelineEmpty) timeline = null;
    }
}
