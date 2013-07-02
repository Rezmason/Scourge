package net.rezmason.scourge.textview.text;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Style {

    var values:Map<String, Dynamic>;

    var basics:Array<Float>;

    public var name(default, null):String;
    public var basis(default, null):String;

    var glyphs:Array<Glyph>;
    var mouseID:Int;
    var paint:Int;

    static var styleFields:Array<String> = ['r', 'g', 'b', 'i', 's', 'p'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic, ?mouseID:Int):Void {
        values = new Map<String, Dynamic>();
        if (initValues == null) initValues = {};
        for (field in styleFields) values[field] = cast Reflect.field(initValues, field);
        this.name = name;
        this.basis = basis;
        this.mouseID = 0;
        glyphs = [];
    }

    public function copy():Style {
        var dupe:Style = new Style('${name}_copy');
        dupe.inherit(this);
        return dupe;
    }

    public function addGlyph(glyph:Glyph):Void {
        if (glyphs.length == 0) paint = (glyph.get_paint() & 0xFF0000) | (mouseID & 0xFFFF);
        else glyph.set_paint(paint);
        glyphs.push(glyph);
    }

    public function removeAllGlyphs():Void glyphs = [];

    public function updateGlyphs(delta:Float):Void {

        if (glyphs.length == 0) return;

        var r:Float = basics[0];
        var g:Float = basics[1];
        var b:Float = basics[2];
        var i:Float = basics[3];
        var s:Float = basics[4];
        var p:Float = basics[5];

        for (glyph in glyphs) {
            glyph.set_color(r, g, b);
            glyph.set_i(i);
            glyph.set_s(s);
            glyph.set_p(p);
        }
    }

    public function interact(type:MouseInteractionType):Void {

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
        basics = [];
        for (ike in 0...styleFields.length) basics[ike] = Std.parseFloat('${values[styleFields[ike]]}');
    }
}
