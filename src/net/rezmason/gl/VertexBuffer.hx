package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import lime.graphics.opengl.GL;
import lime.utils.Float32Array;

@:allow(net.rezmason.gl)
class VertexBuffer extends Artifact {

    var buf:NativeVertexBuffer;
    var data:Float32Array;
    var usage:BufferUsage;
    var invalid:Bool;
    public var numVertices(default, null):Int;
    public var footprint(default, null):Int;

    public function new(numVertices:Int, footprint:Int, ?usage:BufferUsage):Void {
        super();
        this.footprint = footprint;
        this.numVertices = numVertices;
        if (usage == null) usage = BufferUsage.STATIC_DRAW;
        this.usage = usage;
        data = new Float32Array(footprint * numVertices);
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        buf = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, buf);
        GL.bufferData(GL.ARRAY_BUFFER, data, usage);
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
            GL.bindBuffer(GL.ARRAY_BUFFER, buf);
            GL.bufferData(GL.ARRAY_BUFFER, data, usage);
            invalid = false;
        }
    }

    override public function dispose():Void {
        super.dispose();
        data = null;
        buf = null;
        footprint = -1;
        numVertices = -1;
    }

    public inline function acc(index:UInt) return data[index];

    public inline function mod(index:UInt, val:Float):Float {
        data[index] = val;
        invalidate();
        return val;
    }
}
