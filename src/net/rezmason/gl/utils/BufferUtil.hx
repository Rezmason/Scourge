package net.rezmason.gl.utils;

import net.rezmason.gl.Data;
import net.rezmason.gl.utils.Util;

class BufferUtil extends Util {

    public inline function createVertexBuffer(numVertices:Int, footprint:Int):VertexBuffer {
        #if flash return context.createVertexBuffer(numVertices, footprint);
        #else return new VertexBuffer(numVertices, footprint);
        #end
    }

    public inline function createIndexBuffer(numIndices:Int):IndexBuffer {
        #if flash return context.createIndexBuffer(numIndices);
        #else return new IndexBuffer(numIndices);
        #end
    }
}
