package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.BufferUsage;
#if ogl 
    import lime.graphics.opengl.GL;
#end

typedef VertexArray = #if ogl lime.utils.Float32Array #end ;

@:allow(net.rezmason.gl)
class VertexBuffer extends Artifact {

    var buf:NativeVertexBuffer;
    var data:VertexArray;
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
        data = new VertexArray(footprint * numVertices);
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if ogl
            buf = GL.createBuffer();
            GL.bindBuffer(GL.ARRAY_BUFFER, buf);
            GL.bufferData(GL.ARRAY_BUFFER, data, usage);
        #end
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
            #if ogl
                GL.bindBuffer(GL.ARRAY_BUFFER, buf);
                GL.bufferData(GL.ARRAY_BUFFER, data, usage);
            #end
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
