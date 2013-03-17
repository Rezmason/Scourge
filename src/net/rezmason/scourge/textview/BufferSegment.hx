package net.rezmason.scourge.textview;

import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.Vector;

typedef BufferSegment = {
    var id:Int;

    var colorBuffer:VertexBuffer3D;
    var geomBuffer:VertexBuffer3D;
    var idBuffer:VertexBuffer3D;
    var indexBuffer:IndexBuffer3D;

    var colorVertices:Vector<Float>;
    var geomVertices:Vector<Float>;
    var idVertices:Vector<Float>;
    var indices:Vector<UInt>;

    var ids:Vector<Int>; // TEMP

    var numQuads:Int;
}
