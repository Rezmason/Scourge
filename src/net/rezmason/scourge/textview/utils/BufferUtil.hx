package net.rezmason.scourge.textview.utils;

import net.rezmason.scourge.textview.core.Types;

class BufferUtil extends Util {

    public inline function createVertexBuffer(numVertices:Int, footprint:Int):VertexBuffer {
        return new VertexBuffer(footprint);
    }

    public inline function createIndexBuffer(numIndices:Int):IndexBuffer {
        return new IndexBuffer();
    }
}
