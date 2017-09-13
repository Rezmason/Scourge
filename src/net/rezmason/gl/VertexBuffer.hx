package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.utils.Float32Array;

@:allow(net.rezmason.gl)
class VertexBuffer extends Artifact {

    var nativeBuffer:GLBuffer;
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
    
        nativeBuffer = context.createBuffer();
        invalidate();
        upload();
    }

    public inline function invalidate():Void invalid = true;

    public inline function upload():Void {
        checkContext();
        if (invalid) {
            context.bindBuffer(context.ARRAY_BUFFER, nativeBuffer);
            context.bufferData(context.ARRAY_BUFFER, data, usage);
            invalid = false;
        }
    }

    override public function dispose():Void {
        super.dispose();
        checkContext();
        context.deleteBuffer(nativeBuffer);
        data = null;
        nativeBuffer = null;
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
