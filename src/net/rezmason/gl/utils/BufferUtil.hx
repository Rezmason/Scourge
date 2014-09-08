package net.rezmason.gl.utils;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;
import net.rezmason.gl.utils.Util;

class BufferUtil extends Util {

    public inline function createVertexBuffer(numVertices:Int, footprint:Int, ?usage:BufferUsage):VertexBuffer {
        return new VertexBuffer(context, numVertices, footprint, usage);
    }

    public inline function createIndexBuffer(numIndices:Int, ?usage:BufferUsage):IndexBuffer {
        return new IndexBuffer(context, numIndices, usage);
    }
}
