package net.rezmason.gl.utils;

import net.rezmason.gl.Types;

class BufferUtil extends Util {

    public inline function createVertexBuffer(numVertices:Int, footprint:Int):VertexBuffer {
        return new VertexBuffer(numVertices, footprint);
    }

    public inline function createIndexBuffer(numIndices:Int):IndexBuffer {
        return new IndexBuffer(numIndices);
    }
}
