package net.rezmason.hypertype.text;

import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.MouseInteractionType;

using net.rezmason.hypertype.core.GlyphUtils;

class Style {

    var values:Map<String, Dynamic>;
    var stateStyles:Array<Style>;
    var states:Array<Array<Float>>;

    public var isInteractive(default, null):Bool;
    public var name(default, null):String;
    public var basis(default, null):String;

    static var styleFields:Array<String> = ['r', 'g', 'b', 'i', 'w', 'a', 'h', 's', 'p'];

    public function new(dec:Dynamic):Void {
        stateStyles = [];
        values = new Map<String, Dynamic>();
        for (field in styleFields) values[field] = cast Reflect.field(dec, field);
        this.name = dec.name;
        this.basis = dec.basis;
        isInteractive = false;
    }

    public function update(spans:Array<Span>, delta:Float, force:Bool):Void {
        for (span in spans) {
            if (force || !span.styled) {
                span.styled = true;
                updateSpan(span, delta);
            }
        }
    }

    function updateSpan(span:Span, delta:Float):Void {
        var glyphs = span.glyphs;
        if (glyphs.length == 0) return;
        var basics = span.basics;
        for (glyph in glyphs) glyph.SET({
            r:basics[0],
            g:basics[1],
            b:basics[2],
            i:basics[3],
            w:basics[4],
            a:basics[5],
            h:basics[6],
            s:basics[7],
            p:basics[8]
        });
    }

    public function handleSpanInteraction(span:Span, type:MouseInteractionType):Void {

    }

    public function toString():String {
        var str:String =  '§ name:$name';
        for (key in values.keys()) str += ', $key:${values[key]}';
        return str;
    }

    public function inherit(parent:Style):Void {
        inheritWithFields(parent, styleFields);
        if (parent != null && basis == parent.name) basis = parent.basis;
    }

    function inheritWithFields(parent:Style, fields:Array<String>):Void {
        if (parent == null) return;
        for (field in fields) if (values[field] == null) values[field] = parent.values[field];
    }

    public function connectBases(bases:Map<String, Style>):Void {
        inherit(bases['']);
    }

    public function removeInteraction(span:Span):Void {

    }

    public function flatten():Void {

        states = [];
        var hasNoStates:Bool = true;

        for (ike in 0...styleFields.length) {
            var field:String = styleFields[ike];
            var doesFieldChange:Bool = false;
            var fieldValues:Array<Float> = [];
            var firstValue = null;

            if (values[field] == null && stateStyles.length > 0) {
                firstValue = stateStyles[0].values[field];
                for (stateStyle in stateStyles) {
                    if (!doesFieldChange && firstValue != stateStyle.values[field]) doesFieldChange = true;
                    fieldValues.push(stateStyle.values[field]);
                }
            }

            if (doesFieldChange) {
                states[ike] = fieldValues;
                hasNoStates = false;
            } else if (values[field] == null) {
                states[ike] = null;
                values[field] = firstValue;
            }
        }

        if (hasNoStates) states = null;
    }

    public function connectSpan(span:Span):Void {
        for (ike in 0...styleFields.length) {
            var val:Float = Std.parseFloat('${values[styleFields[ike]]}');
            if (Math.isNaN(val)) val = 0;
            span.basics[ike] = val;
        }
    }

    private function connectStates(bases:Map<String, Style>, stateNames:Array<String>):Void {
        if (stateNames.length > 0) {
            for (ike in 0...stateNames.length) {
                var stateStyle:Style = new Style({name:'${name}_$ike'});
                if (stateNames[ike] == null || bases[stateNames[ike]] == null) stateStyle.inherit(this);
                else stateStyle.inherit(bases[stateNames[ike]]);
                stateStyle.inherit(bases['']);
                stateStyles.push(stateStyle);
            }
        } else {
            inherit(bases['']);
        }
    }

    private function interpolateSpan(span:Span, state1:Int, state2:Int, ratio:Float):Void {
        if (states == null) return;
        var basics = span.basics;
        for (ike in 0...states.length) {
            var fieldValues:Array<Float> = states[ike];
            if (fieldValues != null) basics[ike] = fieldValues[state1] * (1 - ratio) + fieldValues[state2] * ratio;
        }
    }
}
