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
    var charCode:Int;

    function new(id:Int, shape:VertexArray, color:VertexArray, paint:VertexArray):Void {
        this.id = id;
        GlyphUtils.transfer(this, shape, color, paint);
    }
}
