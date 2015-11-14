package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
#if !flash import lime.graphics.opengl.GL; #end

typedef IndexArray = #if flash flash.Vector<UInt> #else lime.utils.Int16Array #end ;

@:allow(net.rezmason.gl) 
class IndexBuffer extends Artifact {

    var buf:NativeIndexBuffer;
    var data:IndexArray;
    var usage:BufferUsage;
    public var numIndices(default, null):Int;

    function new(numIndices:Int, ?usage:BufferUsage):Void {
        super();
        this.numIndices = numIndices;
        if (usage == null) usage = BufferUsage.STATIC_DRAW;
        this.usage = usage;
        data = new IndexArray(numIndices);
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash 
            buf = context.createIndexBuffer(numIndices, usage);
        #else
            buf = GL.createBuffer();
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
            GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, data, GL.STATIC_DRAW);
        #end
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash if (buf != null) buf.dispose(); #end
        buf = null;
    }

    public inline function upload():Void {
        #if flash
            buf.uploadFromVector(data, 0, numIndices);
        #else
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
            GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, data, GL.STATIC_DRAW);
        #end
    }

    override public function dispose():Void {
        super.dispose();
        #if flash buf.dispose(); #end
        buf = null;
        data = null;
        numIndices = -1;
    }

    public inline function acc(index:UInt) return data[index];

    public inline function mod(index:UInt, val:UInt):UInt {
        data[index] = val;
        // TODO: dirty, min-max
        return val;
    }
}
