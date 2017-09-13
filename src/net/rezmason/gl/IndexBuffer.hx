package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.utils.Int16Array;

@:allow(net.rezmason.gl) 
class IndexBuffer extends Artifact {

    var nativeBuffer:GLBuffer;
    var data:Int16Array;
    var usage:BufferUsage;
    var invalid:Bool;
    public var numIndices(default, null):Int;

    public function new(numIndices:Int, ?usage:BufferUsage):Void {
        super();
        this.numIndices = numIndices;
        if (usage == null) usage = BufferUsage.STATIC_DRAW;
        this.usage = usage;
        data = new Int16Array(numIndices);
    
        nativeBuffer = context.createBuffer();
        invalidate();
        upload();
    }

    public inline function invalidate():Void invalid = true;

    public inline function upload():Void {
        checkContext();
        context.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, nativeBuffer);
        context.bufferData(GL.ELEMENT_ARRAY_BUFFER, data, usage);
        invalid = false;
    }

    override public function dispose():Void {
        super.dispose();
        context.deleteBuffer(nativeBuffer);
        nativeBuffer = null;
        data = null;
        numIndices = -1;
    }

    public inline function acc(index:UInt) return data[index];

    public inline function mod(index:UInt, val:UInt):UInt {
        data[index] = val;
        invalidate();
        return val;
    }
}
