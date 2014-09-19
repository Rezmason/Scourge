package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.BufferUsage;
import net.rezmason.gl.Data;

#if !flash
    import openfl.gl.GL;
#end

@:allow(net.rezmason.gl)
class VertexBuffer extends Artifact {
    var buf:NativeVertexBuffer;
    public var footprint(default, null):Int;
    public var numVertices(default, null):Int;
    #if !flash
        var array:VertexArray;
    #end
    var usage:BufferUsage;

    public function new(numVertices:Int, footprint:Int, ?usage:BufferUsage):Void {
        this.footprint = footprint;
        this.numVertices = numVertices;
        if (usage == null) usage = BufferUsage.STATIC_DRAW;
        this.usage = usage;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash
            buf = context.createVertexBuffer(numVertices, footprint/*, usage*/);
        #else
            buf = GL.createBuffer();
            array = new VertexArray(footprint * numVertices);
        #end
    }

    public inline function uploadFromVector(data:VertexArray, offset:Int, num:Int):Void {
        if (offset < 0 || offset > numVertices) {

        } else {
            if (offset + num > numVertices) num = numVertices - offset;

            #if flash
                buf.uploadFromVector(data, offset, num);
            #elseif js
                if (num * footprint < data.length) data = data.subarray(0, num * footprint);
                array.set(data, offset);
                GL.bindBuffer(GL.ARRAY_BUFFER, buf);
                GL.bufferData(GL.ARRAY_BUFFER, array, usage);
            #else
                for (ike in 0...num * footprint) {
                    array[ike + offset * footprint] = data[ike];
                }
                GL.bindBuffer(GL.ARRAY_BUFFER, buf);
                GL.bufferData(GL.ARRAY_BUFFER, array, usage);
            #end
        }
    }

    public inline function dispose():Void {
        #if flash 
            if (buf != null) buf.dispose(); 
        #else
            array = null;
        #end
        
        buf = null;
        footprint = -1;
        numVertices = -1;
    }
}
