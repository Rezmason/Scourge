package net.rezmason.scourge.textview;

import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.Vector;

class BufferSegment {
    public var id:Int;

    public var colorBuffer:VertexBuffer3D;
    public var geomBuffer:VertexBuffer3D;
    public var idBuffer:VertexBuffer3D;
    public var indexBuffer:IndexBuffer3D;

    public var colorVertices:Vector<Float>;
    public var geomVertices:Vector<Float>;
    public var idVertices:Vector<Float>;
    public var indices:Vector<UInt>;

    public var numGlyphs:Int;

    public function new():Void {}
}
