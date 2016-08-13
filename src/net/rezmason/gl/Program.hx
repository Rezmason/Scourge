package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.utils.GLUtils;

@:allow(net.rezmason.gl)
class Program extends Artifact {

    static var floatVecFuncs:Map<UInt, GLUniformLocation->Float32Array->Void> = [
        1 => GL.uniform1fv,
        2 => GL.uniform2fv,
        3 => GL.uniform3fv,
        4 => GL.uniform4fv,
    ];

    static var intVecFuncs:Map<UInt, GLUniformLocation->Int32Array->Void> = [
        1 => GL.uniform1iv,
        2 => GL.uniform2iv,
        3 => GL.uniform3iv,
        4 => GL.uniform4iv,
    ];

    var nativeProgram:GLProgram;
    var vertSource:String;
    var fragSource:String;

    var uniformLocations:Map<String, GLUniformLocation>;
    var attribsLocations:Map<String, Int>;
    
    public function new(vertSource:String, fragSource:String, extensions:Array<String> = null):Void {
        super(extensions);
        if (extensions != null) {
            var extensionPreamble = '\n';
            for (extension in extensions) {
                GL.getExtension(extension);
                extensionPreamble += '#extension GL_$extension : enable\n';
            }
            #if !desktop extensionPreamble += 'precision mediump float;\n'; #end
            vertSource = extensionPreamble + vertSource;
            fragSource = extensionPreamble + fragSource;
        }

        this.vertSource = vertSource;
        this.fragSource = fragSource;
        
        nativeProgram = GLUtils.createProgram(vertSource, fragSource);

        uniformLocations = new Map();
        for (ike in 0...GL.getProgramParameter(nativeProgram, GL.ACTIVE_UNIFORMS)) {
            var activeUniform = GL.getActiveUniform(nativeProgram, ike);
            var uniformLocation = GL.getUniformLocation(nativeProgram, activeUniform.name);
            uniformLocations[activeUniform.name.split('[')[0]] = uniformLocation;
        }

        attribsLocations = new Map();
        for (ike in 0...GL.getProgramParameter(nativeProgram, GL.ACTIVE_ATTRIBUTES)) {
            attribsLocations[GL.getActiveAttrib(nativeProgram, ike).name.split('[')[0]] = ike;
        }
    }

    public inline function setMatrix4(uName:String, matrix:Matrix4):Void {
        var location = getUniformLocation(uName);
        if (location != null) GL.uniformMatrix4fv(location, false, matrix);
    }

    public inline function setVector4(uName:String, vec4:Vector4):Void {
        var location = getUniformLocation(uName);
        if (location != null) GL.uniform4f(location, vec4.x, vec4.y, vec4.z, vec4.w);
    }

    public inline function setFloat(uName:String, x:Float, ?y:Float, ?z:Float, ?w:Float):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
            if (w != null) GL.uniform4f(location, x, y, z, w);
            else if (z != null) GL.uniform3f(location, x, y, z);
            else if (y != null) GL.uniform2f(location, x, y);
            else GL.uniform1f(location, x);
        }
    }

    public inline function setFloatVec(uName:String, degree:UInt, vec:Float32Array):Void {
        var location = getUniformLocation(uName);
        if (location != null) floatVecFuncs[degree](location, vec);
    }

    public inline function setInt(uName:String, x:Int, ?y:Int, ?z:Int, ?w:Int):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
            if (w != null) GL.uniform4i(location, x, y, z, w);
            else if (z != null) GL.uniform3i(location, x, y, z);
            else if (y != null) GL.uniform2i(location, x, y);
            else GL.uniform1i(location, x);
        }
    }

    public inline function setIntVec(uName:String, degree:UInt, vec:Int32Array):Void {
        var location = getUniformLocation(uName);
        if (location != null) intVecFuncs[degree](location, vec);
    }

    public inline function setRenderTarget(renderTarget:RenderTarget):Void {
        GL.bindFramebuffer(GL.FRAMEBUFFER, renderTarget.frameBuffer);
        GL.viewport(0, 0, renderTarget.width, renderTarget.height);
    }
    
    public inline function setTexture(uName:String, texture:Texture, index:Int = 0):Void {
        var location = getUniformLocation(uName);
        var nativeTexture = texture != null ? texture.nativeTexture : null;
        if (location != null) {
            GL.activeTexture(GL.TEXTURE0 + index);
            GL.bindTexture (GL.TEXTURE_2D, nativeTexture);
            GL.uniform1i(location, index);
        }
    }

    public inline function setVertexBuffer(aName:String, buffer:VertexBuffer, offset:UInt, size:UInt):Void {
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

    public inline function clear(color:Vector4) {
        GL.clearColor(color.x, color.y, color.z, color.w);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    }

    public inline function draw(indexBuffer:IndexBuffer, firstIndex:UInt = 0, numTriangles:UInt = 0):Void {
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.nativeBuffer);
        GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);
    }

    inline function getUniformLocation(name:String):Null<GLUniformLocation> return uniformLocations[name];

    inline function getAttribsLocation(name:String):Null<Int> return attribsLocations[name];
}
