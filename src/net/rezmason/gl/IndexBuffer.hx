package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

#if !flash
    import openfl.gl.GL;
#end

@:allow(net.rezmason.gl) 
class IndexBuffer extends Artifact {

    var buf:NativeIndexBuffer;
    var array:IndexArray;
    var usage:BufferUsage;
    public var numIndices(default, null):Int;

    function new(numIndices:Int, ?usage:BufferUsage):Void {
        this.numIndices = numIndices;
        this.usage = usage;
        #if !flash
            array = new IndexArray(numIndices);
        #end
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash 
            buf = context.createIndexBuffer(numIndices/*, usage*/);
        #else
            buf = GL.createBuffer();
        #end
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash
            buf.dispose();
        #end
    }

    public inline function uploadFromVector(data:IndexArray, offset:Int, num:Int):Void {
        if (offset < 0 || offset > numIndices) {

        } else {
            if (offset + num > numIndices) num = numIndices - offset;

            #if flash
                buf.uploadFromVector(data, offset, num);
            #elseif js
                if (num < data.length) data = data.subarray(0, num);
                array.set(data, offset);
                GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
                GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, array, GL.STATIC_DRAW);
            #else
                for (ike in 0...num) array[ike + offset] = data[ike];
                GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
                GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, array, GL.STATIC_DRAW);
            #end
        }
    }

    public inline function dispose():Void {
        #if flash
            buf.dispose();
        #end
        buf = null;
        array = null;
        numIndices = -1;
    }
}
