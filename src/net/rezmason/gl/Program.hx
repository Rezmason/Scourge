package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.Matrix4;
import lime.utils.GLUtils;

@:allow(net.rezmason.gl)
class Program extends Artifact {

    var nativeProgram:GLProgram;
    var vertSource:String;
    var fragSource:String;

    var uniformLocations:Map<String, GLUniformLocation>;
    var attribsLocations:Map<String, Int>;
    
    public function new(vertSource:String, fragSource:String, extensions:Array<String> = null):Void {

        if (extensions != null) {
            var extensionPreamble = '\n';
            for (extension in extensions) {
                GL.getExtension(extension);
                extensionPreamble += '#extension GL_$extension : enable\n';
            }
            #if !desktop extensionPreamble += 'precision mediump float;\n'; #end
            fragSource = extensionPreamble + fragSource;
        }

        this.vertSource = vertSource;
        this.fragSource = fragSource;
        
        uniformLocations = new Map();
        attribsLocations = new Map();
        nativeProgram = GLUtils.createProgram(vertSource, fragSource);
    }

    public inline function setMatrix4(uName:String, matrix:Matrix4):Void {
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
                GL.bindBuffer(GL.ARRAY_BUFFER, buffer.nativeBuffer);
                GL.vertexAttribPointer(location, size, GL.FLOAT, false, 4 * buffer.footprint, 4 * offset);
                GL.enableVertexAttribArray(location);
            } else {
                GL.disableVertexAttribArray(location);
            }
        }
    }

    public inline function use() GL.useProgram(nativeProgram);

    public inline function setBlendFactors(sourceFactor:BlendFactor, destinationFactor:BlendFactor):Void {
        GL.enable(GL.BLEND);
        GL.blendFunc(sourceFactor, destinationFactor);
    }

    public inline function setDepthTest(enabled:Bool):Void {
        if (enabled) GL.enable(GL.DEPTH_TEST);
        else GL.disable(GL.DEPTH_TEST);
    }

    public inline function clear(r:Float, g:Float, b:Float, a:Float) {
        GL.clearColor(r, g, b, a);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    }

    public inline function draw(indexBuffer:IndexBuffer, firstIndex:UInt = 0, numTriangles:UInt = 0):Void {
        indexBuffer.bind();
        GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);
    }

    inline function getUniformLocation(name:String):Null<GLUniformLocation> {
        if (!uniformLocations.exists(name)) {
            uniformLocations[name] = GL.getUniformLocation(nativeProgram, name);
        }
        return uniformLocations[name];
    }

    inline function getAttribsLocation(name:String):Null<Int> {
        if (!attribsLocations.exists(name)) {
            attribsLocations[name] = GL.getAttribLocation(nativeProgram, name);
        }
        return attribsLocations[name];
    }
}
