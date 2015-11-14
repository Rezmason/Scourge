package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.BufferUsage;
#if !flash import lime.graphics.opengl.GL; #end

typedef VertexArray = #if flash flash.Vector<Float> #else lime.utils.Float32Array #end ;

@:allow(net.rezmason.gl)
class VertexBuffer extends Artifact {

    var buf:NativeVertexBuffer;
    public var footprint(default, null):Int;
    public var numVertices(default, null):Int;
    var data:VertexArray;
    var usage:BufferUsage;

    public function new(numVertices:Int, footprint:Int, ?usage:BufferUsage):Void {
        super();
        this.footprint = footprint;
        this.numVertices = numVertices;
        if (usage == null) usage = BufferUsage.STATIC_DRAW;
        this.usage = usage;
        data = new VertexArray(footprint * numVertices);
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash
            buf = context.createVertexBuffer(numVertices, footprint, usage);
        #else
            buf = GL.createBuffer();
            GL.bindBuffer(GL.ARRAY_BUFFER, buf);
            GL.bufferData(GL.ARRAY_BUFFER, data, usage);
        #end
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash if (buf != null) buf.dispose(); #end
        buf = null;
    }

    public inline function upload():Void {
        #if flash
            buf.uploadFromVector(data, 0, numVertices);
        #else
            GL.bindBuffer(GL.ARRAY_BUFFER, buf);
            GL.bufferData(GL.ARRAY_BUFFER, data, usage);
        #end
    }

    override public function dispose():Void {
        super.dispose();
        #if flash if (buf != null) buf.dispose(); #end
        data = null;
        buf = null;
        footprint = -1;
        numVertices = -1;
    }

    public inline function acc(index:UInt) return data[index];

    public inline function mod(index:UInt, val:Float):Float {
        data[index] = val;
        // TODO: dirty, min-max
        return val;
    }
}
