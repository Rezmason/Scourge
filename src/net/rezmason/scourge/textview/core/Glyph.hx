package net.rezmason.scourge.textview.core;

import net.rezmason.gl.Types;

@:allow(net.rezmason.scourge.textview.core.BodySegment)
@:allow(net.rezmason.scourge.textview.core.GlyphUtils)
class Glyph {

    public var id(default, null):Int;

    var shape:VertexArray;
    var color:VertexArray;
    var paint:VertexArray;

    var paintHex:Int;
    var visible:Bool;
    var charCode:Int;
    var indexAddress:Int;

    function new(id:Int, shape:VertexArray, color:VertexArray, paint:VertexArray):Void {
        this.id = id;
        this.shape = shape;
        this.color = color;
        this.paint = paint;
        GlyphUtils.makeCorners(this);
        GlyphUtils.set_color(this, 1, 1, 1);
        GlyphUtils.set_s(this, 1);
        visible = true;
    }
}
