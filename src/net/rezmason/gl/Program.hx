package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

import lime.graphics.opengl.GL;
import lime.utils.GLUtils;

@:allow(net.rezmason.gl)
class Program extends Artifact {

    var prog:NativeProgram;
    var vertSource:String;
    var fragSource:String;

    var uniformLocations:Map<String, UniformLocation>;
    var attribsLocations:Map<String, AttribsLocation>;
    
    function new(vertSource:String, fragSource:String):Void {
        super();
        this.vertSource = vertSource;
        this.fragSource = fragSource;
    }

    override function connectToContext(context:Context):Void {
        uniformLocations = new Map();
        attribsLocations = new Map();
        super.connectToContext(context);
        prog = GLUtils.createProgram(vertSource, fragSource);
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        prog = null;
        uniformLocations = null;
        attribsLocations = null;
    }

    public inline function setProgramConstantsFromMatrix(uName:String, matrix:Matrix4):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
            GL.uniformMatrix4fv(location, false, matrix);
        }
    }

    public inline function setFourProgramConstants(uName:String, vals:Array<Float>):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
            if (vals == null) GL.uniform4f(location, 0, 0, 0, 0);
            else GL.uniform4f(location, vals[0], vals[1], vals[2], vals[3]);
        }
    }

    public inline function setTextureAt(uName:String, texture:Texture, index:Int = 0):Void {
        var location = getUniformLocation(uName);
        if (location != null && texture != null) {
            GL.activeTexture(GL.TEXTURE0 + index);
            GL.bindTexture (GL.TEXTURE_2D, texture.nativeTexture);
            GL.uniform1i(location, index);
        }
    }

    public inline function setVertexBufferAt(aName:String, buffer:VertexBuffer, offset:UInt, size:UInt):Void {
        var location = getAttribsLocation(aName);
        if (location != null) {
            if (size < 0) size = buffer.footprint;
            if (buffer != null) {
                GL.bindBuffer(GL.ARRAY_BUFFER, buffer.buf);
                GL.vertexAttribPointer(location, size, GL.FLOAT, false, 4 * buffer.footprint, 4 * offset);
                GL.enableVertexAttribArray(location);
            } else {
                GL.disableVertexAttribArray(location);
            }
        }
    }

    inline function getUniformLocation(name:String):Null<UniformLocation> {
        if (!uniformLocations.exists(name)) {
            uniformLocations[name] = GL.getUniformLocation(prog, name);
        }
        return uniformLocations[name];
    }

    inline function getAttribsLocation(name:String):Null<AttribsLocation> {
        if (!attribsLocations.exists(name)) {
            attribsLocations[name] = GL.getAttribLocation(prog, name);
        }
        return attribsLocations[name];
    }
}
