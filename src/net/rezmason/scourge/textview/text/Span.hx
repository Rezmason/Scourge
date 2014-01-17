package net.rezmason.scourge.textview.text;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef SpanState = {};

@:allow(net.rezmason.scourge.textview.text)
class Span {

    public var style(default, null):Style;
    public var id(default, null):String;

    var basics:Array<Float>;

    var glyphs:Array<Glyph>;
    var mouseID:Int;
    var state:SpanState;

    public function new():Void {
        reset();
    }

    public function reset():Void {
        mouseID = 0;
        style = null;
        glyphs = null;
        basics = null;
    }

    public function init(style:Style, mouseID:Int, id:String):Void {
        this.mouseID = mouseID;
        this.style = style;
        this.id = id;
        glyphs = [];
        basics = [];
    }

    public inline function addGlyph(glyph:Glyph):Void {
        glyph.set_paint(mouseID);
        glyphs.push(glyph);
    }

    public inline function connect():Void style.connectSpan(this);
    public inline function removeAllGlyphs():Void glyphs = [];
    public inline function update(delta:Float):Void style.updateSpan(this, delta);
    public inline function receiveInteraction(type:MouseInteractionType):Void style.handleSpanInteraction(this, type);
}
