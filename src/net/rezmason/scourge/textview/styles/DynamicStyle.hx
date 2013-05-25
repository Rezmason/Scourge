package net.rezmason.scourge.textview.styles;

class DynamicStyle extends Style {

    var stateStyles:Array<Style>;
    var states:Map<String, Array<Float>>;

    public function new(?name:String, ?basis:String, ?initValues:Dynamic, ?mouseID:Int):Void {
        stateStyles = [];
        super(name, basis, initValues, mouseID);
    }

    private function connectStates(bases:Map<String, Style>, stateNames:Array<String>):Void {
        if (stateNames.length > 0) {
            for (ike in 0...stateNames.length) {
                var stateStyle:Style = new Style('${name}_$ike');
                if (stateNames[ike] == null || bases[stateNames[ike]] == null) stateStyle.inherit(this);
                else stateStyle.inherit(bases[stateNames[ike]]);
                stateStyle.inherit(bases[""]);
                stateStyles.push(stateStyle);
            }
        } else {
            inherit(bases[""]);
        }
    }

    private function interpolateGlyphs(fromIndex:Int, toIndex:Int, ratio:Float):Void {
        if (states != null) {
            for (key in states.keys()) {
                var fieldValues:Array<Float> = states[key];
                values.set(key, fieldValues[fromIndex] * (1 - ratio) + fieldValues[toIndex] * ratio);
            }
        }
    }

    override public function flatten():Void {

        states = new Map();
        var hasNoStates:Bool = true;

        for (field in Style.styleFields) {
            var doesFieldChange:Bool = false;
            var fieldValues:Array<Float> = [];
            var firstValue:Null<Float> = null;

            if (values[field] == null && stateStyles.length > 0) {
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
