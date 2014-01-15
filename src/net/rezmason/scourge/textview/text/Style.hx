package net.rezmason.scourge.textview.text;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.utils.Siphon;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Style {

    var values:Map<String, Dynamic>;
    var stateStyles:Array<Style>;
    var states:Array<Array<Float>>;

    public var isInteractive(default, null):Bool;
    public var name(default, null):String;
    public var basis(default, null):String;

    static var easeLibrary:Map<String, Float->Float> = makeEaseLibrary();

    static var styleFields:Array<String> = ['r', 'g', 'b', 'i', 'f', 's', 'p'];

    public function new(dec:Dynamic):Void {
        stateStyles = [];
        values = new Map<String, Dynamic>();
        for (field in styleFields) values[field] = cast Reflect.field(dec, field);
        this.name = dec.name;
        this.basis = dec.basis;
        isInteractive = false;
    }

    public function updateSpan(span:Span, delta:Float):Void {

        var glyphs = span.glyphs;
        var basics = span.basics;

        if (glyphs.length == 0) return;

        var r:Float = basics[0];
        var g:Float = basics[1];
        var b:Float = basics[2];
        var i:Float = basics[3];
        var f:Float = basics[4];
        var s:Float = basics[5];
        var p:Float = basics[6];

        for (glyph in glyphs) {
            glyph.set_rgb(r, g, b);
            glyph.set_i(i);
            glyph.set_f(f);
            glyph.set_s(s);
            glyph.set_p(p);
        }
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

    public function initializeSpan(span:Span):Void {
        for (ike in 0...styleFields.length) span.basics[ike] = Std.parseFloat('${values[styleFields[ike]]}');
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

    static function makeEaseLibrary():Map<String, Float->Float> {
        var lib:Map<String, Float->Float> = new Map();

        var easeClasses:Map<String, Class<Dynamic>> = cast Siphon.getDefs('net.kawa.tween.easing', 'src');

        for (key in easeClasses.keys()) {
            var clazz = easeClasses[key];
            for (field in Type.getClassFields(clazz)) {
                var easeFunc:Dynamic = cast Reflect.field(clazz, field);
                if (Reflect.isFunction(easeFunc)) lib['${key}_$field'] = cast easeFunc;
            }
        }
        return lib;
    }
}
