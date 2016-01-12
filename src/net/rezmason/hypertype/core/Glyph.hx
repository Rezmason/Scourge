package net.rezmason.hypertype.core;

import net.rezmason.gl.VertexBuffer;
import net.rezmason.math.Vec3;

@:allow(net.rezmason.hypertype.core.BodySegment)
@:allow(net.rezmason.hypertype.core.GlyphUtils)
class Glyph {

    public var id(default, null):Int;

    var geometryBuf:VertexBuffer;
    var colorBuf:VertexBuffer;
    var fontBuf:VertexBuffer;
    var hitboxBuf:VertexBuffer;
    var color:Vec3;
    var hitboxID:Int;
    var charCode:Int;
    var font:GlyphFont;

    function new(id:Int = 0):Void this.id = id;
}
