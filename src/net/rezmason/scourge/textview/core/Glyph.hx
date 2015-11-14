package net.rezmason.scourge.textview.core;

import net.rezmason.gl.VertexBuffer;
import net.rezmason.utils.display.FlatFont;

@:allow(net.rezmason.scourge.textview.core.BodySegment)
@:allow(net.rezmason.scourge.textview.core.GlyphUtils)
class Glyph {

    public var id(default, null):Int;

    var shape:VertexBuffer;
    var color:VertexBuffer;
    var paint:VertexBuffer;

    var paintHex:Int;
    var charCode:Int;
    var font:FlatFont;

    function new(id:Int = 0):Void this.id = id;
}
