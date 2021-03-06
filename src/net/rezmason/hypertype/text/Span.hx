package net.rezmason.hypertype.text;

import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.MouseInteractionType;

using net.rezmason.hypertype.core.GlyphUtils;

typedef SpanState = {};

@:allow(net.rezmason.hypertype.text)
class Span {

    public var style(default, null):Style;
    public var id(default, null):String;

    var basics:Array<Float>;

    var glyphs:Array<Glyph>;
    var mouseID:Int;
    var isInteractive:Bool;
    var state:SpanState;
    var styled:Bool;

    public function new():Void {
        reset();
    }

    public function reset():Void {
        mouseID = 0;
        style = null;
        glyphs = null;
        basics = null;
        isInteractive = true;
        styled = false;
    }

    public function init(style:Style, mouseID:Int, id:String):Void {
        this.style = style;
        this.id = id;
        glyphs = [];
        basics = [];
        styled = false;
        setMouseID(mouseID);
    }

    public inline function addGlyph(glyph:Glyph):Void {
        hitboxGlyph(glyph, isInteractive ? mouseID : 0);
        glyphs.push(glyph);
    }

    public inline function setMouseID(mouseID:Int):Void {
        this.mouseID = mouseID & 0x00FFFF;
        if (isInteractive) for (glyph in glyphs) hitboxGlyph(glyph, mouseID);
    }

    public inline function setInteractive(val:Bool):Void {
        if (isInteractive != val) {
            isInteractive = val;
            for (glyph in glyphs) hitboxGlyph(glyph, isInteractive ? mouseID : 0);
        }
    }

    inline function hitboxGlyph(glyph:Glyph, val:Int):Void glyph.set_hitboxID(val);

    public inline function connect():Void style.connectSpan(this);
    public inline function removeAllGlyphs():Void glyphs = [];
    public inline function receiveInteraction(type:MouseInteractionType):Void style.handleSpanInteraction(this, type);

    public inline function copyTo(otherSpan:Span):Span {
        if (otherSpan == null) otherSpan = new Span();
        otherSpan.init(style, mouseID, id);
        otherSpan.connect();
        otherSpan.isInteractive = isInteractive;
        return otherSpan;
    }
}
