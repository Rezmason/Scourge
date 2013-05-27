package net.rezmason.scourge.textview.utils;

import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;

class BufferUtil extends Util {

    public function createVertexBuffer(numVertices:Int, data32PerVertex:Int):VertexBuffer3D {
        return context.createVertexBuffer(numVertices, data32PerVertex);
    }

    public function createIndexBuffer(numIndices:Int):IndexBuffer3D {
        return context.createIndexBuffer(numIndices);
    }
}
