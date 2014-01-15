package net.rezmason.scourge.textview.text;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;

using net.rezmason.scourge.textview.core.GlyphUtils;

@:allow(net.rezmason.scourge.textview.text)
class Span {

    var basics:Array<Float>;

    var glyphs:Array<Glyph>;
    var mouseID:Int;
    var paint:Int;
    var style:Style;
    var state:SpanState;

    public function new(style:Style, mouseID:Int):Void {
        this.mouseID = mouseID;
        this.style = style;
        glyphs = [];
        basics = [];
    }

    public inline function addGlyph(glyph:Glyph):Void {
        if (glyphs.length == 0) paint = (glyph.get_paint() & 0xFF0000) | (mouseID & 0xFFFF);
        glyph.set_paint(paint);
        glyphs.push(glyph);
    }

    public inline function initialize():Void style.initializeSpan(this);
    public inline function removeAllGlyphs():Void glyphs = [];
    public inline function update(delta:Float):Void style.updateSpan(this, delta);
    public inline function receiveInteraction(type:MouseInteractionType):Void style.handleSpanInteraction(this, type);
}
