package net.rezmason.scourge.textview.styles;

import net.rezmason.scourge.textview.core.Glyph;

using Reflect;
using net.rezmason.scourge.textview.core.GlyphUtils;

class Style {

    var values:Map<String, Null<Float>>;

    public var name(default, null):String;
    public var basis(default, null):String;

    var glyphs:Array<Glyph>;

    static var styleFields:Array<String> = ['r', 'g', 'b', 'i', 's', 'p'];

    public function new(?name:String, ?basis:String, ?initValues:Dynamic):Void {
        values = new Map();
        if (initValues == null) initValues = {};
        for (field in styleFields) values.set(field, initValues.field(field));
        this.name = name;
        this.basis = basis;
        glyphs = [];
    }

    public function addGlyph(glyph:Glyph):Void glyphs.push(glyph);

    public function removeAllGlyphs():Void glyphs.splice(0, glyphs.length);

    public function updateGlyphs(delta:Float):Void {
        var r:Float = values['r'];
        var g:Float = values['g'];
        var b:Float = values['b'];
        var i:Float = values['i'];
        var s:Float = values['s'];
        var p:Float = values['p'];

        for (glyph in glyphs) {
            glyph.set_color(r, g, b);
            glyph.set_i(i);
            glyph.set_s(s);
            glyph.set_p(p);
        }
    }

    public function toString():String {
        var str:String =  '§ name:$name';
        for (key in values.keys()) str += ', $key:${values[key]}';
        return str;
    }

    public function inherit(parent:Style):Void {
        if (parent == null) return;
        for (field in styleFields) if (values[field] == null) values.set(field, parent.values[field]);
        if (basis == parent.name) basis = parent.basis;
    }

    public function connectBases(bases:Map<String, Style>):Void {
        inherit(bases[""]);
    }

    public function flatten():Void {

    }
}
