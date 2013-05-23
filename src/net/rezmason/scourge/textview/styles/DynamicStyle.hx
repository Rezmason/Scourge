package net.rezmason.scourge.textview.styles;

import net.kawa.tween.easing.*;

class DynamicStyle extends Style {

    var stateStyles:Array<Style>;
    var states:Map<String, Array<Float>>;
    var easeFunc:Float->Float;

    public function new(?name:String, ?basis:String, ?initValues:Dynamic):Void {
        stateStyles = [];
        easeFunc = Quad.easeInOut;
        super(name, basis, initValues);
    }

    private function connectStates(bases:Map<String, Style>, stateNames:Array<String>):Void {
        for (ike in 0...stateNames.length) {
            var stateStyle:Style = new Style('${name}_$ike');
            stateStyle.inherit(bases[stateNames[ike]]);
            stateStyle.inherit(bases[""]);
            stateStyles.push(stateStyle);
        }
    }

    override public function flatten():Void {

        states = new Map();
        var hasNoStates:Bool = true;

        for (field in Style.styleFields) {
            var doesFieldChange:Bool = false;
            var fieldValues:Array<Float> = [];
            var firstValue:Null<Float> = null;

            if (values[field] == null) {
                firstValue = stateStyles[0].values[field];
                for (stateStyle in stateStyles) {
                    if (!doesFieldChange && firstValue != stateStyle.values[field]) doesFieldChange = true;
                    fieldValues.push(stateStyle.values[field]);
                }
            }

            if (doesFieldChange) {
                states.set(field, fieldValues);
                hasNoStates = false;
            } else if (values[field] == null) {
                values.set(field, firstValue);
            }
        }

        if (hasNoStates) states = null;
    }
}
