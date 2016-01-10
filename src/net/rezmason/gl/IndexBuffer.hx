package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import lime.graphics.opengl.GL;
import lime.utils.Int16Array;

@:allow(net.rezmason.gl) 
class IndexBuffer extends Artifact {

    var buf:NativeIndexBuffer;
    var data:Int16Array;
    var usage:BufferUsage;
    var invalid:Bool;
    public var numIndices(default, null):Int;


    function new(numIndices:Int, ?usage:BufferUsage):Void {
        super();
        this.numIndices = numIndices;
        if (usage == null) usage = BufferUsage.STATIC_DRAW;
        this.usage = usage;
        data = new Int16Array(numIndices);
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        buf = GL.createBuffer();
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, data, GL.STATIC_DRAW);
        invalidate();
        upload();
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        buf = null;
    }

    public inline function invalidate():Void invalid = true;

    public inline function upload():Void {
        if (invalid && isConnectedToContext()) {
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
            GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, data, GL.STATIC_DRAW);
            invalid = false;
        }
    }

    override public function dispose():Void {
        super.dispose();
        buf = null;
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
