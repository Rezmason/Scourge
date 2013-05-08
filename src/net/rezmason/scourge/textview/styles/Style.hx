package net.rezmason.scourge.textview.styles;

import net.rezmason.scourge.textview.core.Glyph;

using Lambda;
using Reflect;
using Type;

using net.rezmason.scourge.textview.core.GlyphUtils;

class BasicStyle {
    var r:Float;
    var g:Float;
    var b:Float;
    var i:Float;
    var s:Float;
    var p:Float;
}

class Style extends BasicStyle {

    public var name:String;
    public var basis:String;

    var glyphs:Array<Glyph>;

    static var styleFields:Array<String> = BasicStyle.getInstanceFields();

    public function new(?name:String):Void {
        r = g = b = i = s = p = Math.NaN;
        this.name = name;
        glyphs = [];
    }

    public function addGlyph(glyph:Glyph):Void {
        glyphs.push(glyph);
    }

    public function removeAllGlyphs():Void {
        glyphs.splice(0, glyphs.length);
    }

    public function updateGlyphs(delta:Float):Void {
        for (glyph in glyphs) {
            glyph.set_color(r, g, b);
            glyph.set_i(i);
            glyph.set_s(s);
            glyph.set_p(p);
        }
    }

    public function toString():String return '§ $name $r $g $b $i $s $p';

    public static function create(tag:Array<String>):Style {
        var style:Style = new Style();

        for (attribute in tag) {
            var elements:Array<String> = attribute.split(":");
            var key:String = elements[0];
            var value:String = elements[1];

            switch (key) {
                case "name": style.name = value;
                case "basis": style.basis = value;
                default: if (styleFields.has(key)) style.setField(key, Std.parseFloat(value));
            }
        }

        return style;
    }

    public static function inherit(style:Style, parentStyle:Style):Void {
        if (parentStyle == null) return;

        for (field in styleFields) {
            if (field.length > 1) continue;
            if (Math.isNaN(style.field(field))) style.setField(field, parentStyle.field(field));
        }
    }
}
