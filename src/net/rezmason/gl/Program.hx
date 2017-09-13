package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.Matrix4;
import lime.math.Vector2;
import lime.math.Vector4;
import lime.utils.Float32Array;
import lime.utils.Int32Array;
import lime.utils.GLUtils;

@:allow(net.rezmason.gl)
class Program extends Artifact {

    var nativeProgram:GLProgram;
    var vertSource:String;
    var fragSource:String;

    var floatVecFuncs:Map<UInt, GLUniformLocation->Float32Array->Void>;
    var intVecFuncs:Map<UInt, GLUniformLocation->Int32Array->Void>;

    var uniformLocations:Map<String, GLUniformLocation>;
    var attribsLocations:Map<String, Int>;
    
    public function new(vertSource:String, fragSource:String, extensions:Array<String> = null):Void {
        super(extensions);
        repopulateVecFunctions();
        if (extensions != null) {
            var extensionPreamble = '\n';
            for (extension in extensions) {
                // context.getExtension(extension); // may be unnecessary
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
        for (ike in 0...context.getProgramParameter(nativeProgram, context.ACTIVE_UNIFORMS)) {
            var activeUniform = context.getActiveUniform(nativeProgram, ike);
            var uniformLocation = context.getUniformLocation(nativeProgram, activeUniform.name);
            uniformLocations[activeUniform.name.split('[')[0]] = uniformLocation;
        }

        attribsLocations = new Map();
        for (ike in 0...context.getProgramParameter(nativeProgram, context.ACTIVE_ATTRIBUTES)) {
            var activeAttrib = context.getActiveAttrib(nativeProgram, ike);
            var attribLocation = context.getAttribLocation(nativeProgram, activeAttrib.name);
            attribsLocations[activeAttrib.name.split('[')[0]] = attribLocation;
        }
    }

    public inline function setMatrix4(uName:String, matrix:Matrix4):Void {
        checkContext();
        var location = getUniformLocation(uName);
        if (location != null && matrix != null) context.uniformMatrix4fv(location, false, matrix);
    }

    public inline function setVector2(uName:String, vec2:Vector2):Void {
        checkContext();
        var location = getUniformLocation(uName);
        if (location != null) context.uniform2f(location, vec2.x, vec2.y);
    }

    public inline function setVector4(uName:String, vec4:Vector4):Void {
        checkContext();
        var location = getUniformLocation(uName);
        if (location != null && vec4 != null) context.uniform4f(location, vec4.x, vec4.y, vec4.z, vec4.w);
    }

    public inline function setFloat(uName:String, x:Float, ?y:Float, ?z:Float, ?w:Float):Void {
        checkContext();
        var location = getUniformLocation(uName);
        if (location != null) {
            if (w != null) context.uniform4f(location, x, y, z, w);
            else if (z != null) context.uniform3f(location, x, y, z);
            else if (y != null) context.uniform2f(location, x, y);
            else context.uniform1f(location, x);
        }
    }

    public inline function setFloatVec(uName:String, degree:UInt, vec:Float32Array):Void {
        var location = getUniformLocation(uName);
        if (location != null && vec != null) floatVecFuncs[degree](location, vec);
    }

    public inline function setInt(uName:String, x:Int, ?y:Int, ?z:Int, ?w:Int):Void {
        checkContext();
        var location = getUniformLocation(uName);
        if (location != null) {
            if (w != null) context.uniform4i(location, x, y, z, w);
            else if (z != null) context.uniform3i(location, x, y, z);
            else if (y != null) context.uniform2i(location, x, y);
            else context.uniform1i(location, x);
        }
    }

    public inline function setIntVec(uName:String, degree:UInt, vec:Int32Array):Void {
        var location = getUniformLocation(uName);
        if (location != null && vec != null) intVecFuncs[degree](location, vec);
    }

    public inline function setRenderTarget(renderTarget:RenderTarget):Void {
        checkContext();
        context.bindFramebuffer(context.FRAMEBUFFER, renderTarget.frameBuffer);
        context.viewport(0, 0, renderTarget.width, renderTarget.height);
    }
    
    public inline function setTexture(uName:String, texture:Texture, index:Int = 0):Void {
        checkContext();
        var location = getUniformLocation(uName);
        var nativeTexture = texture != null ? texture.nativeTexture : null;
        if (location != null) {
            context.activeTexture(context.TEXTURE0 + index);
            context.bindTexture (context.TEXTURE_2D, nativeTexture);
            context.uniform1i(location, index);
        }
    }

    public inline function setVertexBuffer(aName:String, buffer:VertexBuffer, offset:UInt, size:UInt):Void {
        checkContext();
        var location = getAttribsLocation(aName);
        if (location != null) {
            if (size < 0) size = buffer.footprint;
            if (buffer != null) {
                context.bindBuffer(context.ARRAY_BUFFER, buffer.nativeBuffer);
                context.vertexAttribPointer(location, size, context.FLOAT, false, 4 * buffer.footprint, 4 * offset);
                context.enableVertexAttribArray(location);
            } else {
                context.disableVertexAttribArray(location);
            }
        }
    }

    public inline function use() {
        checkContext();
        context.useProgram(nativeProgram);
    }

    public inline function setBlendFactors(sourceFactor:BlendFactor, destinationFactor:BlendFactor):Void {
        checkContext();
        context.enable(context.BLEND);
        context.blendFunc(sourceFactor, destinationFactor);
    }

    public inline function setDepthTest(enabled:Bool):Void {
        checkContext();
        if (enabled) {
            context.enable(context.DEPTH_TEST);
            context.depthFunc(context.LESS);
        } else {
            context.disable(context.DEPTH_TEST);
        }
    }

    public inline function setFaceCulling(culling:Null<FaceCulling>):Void {
        checkContext();
        if (culling != null) {
            context.enable(context.CULL_FACE);
            context.cullFace(culling);
        } else {
            context.disable(context.CULL_FACE);
        }
    }

    public inline function clear(color:Vector4) {
        checkContext();
        context.clearColor(color.x, color.y, color.z, color.w);
        context.clear(context.COLOR_BUFFER_BIT | context.DEPTH_BUFFER_BIT);
    }

    public inline function draw(indexBuffer:IndexBuffer, firstIndex:UInt = 0, numTriangles:UInt = 0):Void {
        checkContext();
        context.bindBuffer(context.ELEMENT_ARRAY_BUFFER, indexBuffer.nativeBuffer);
        context.drawElements(context.TRIANGLES, numTriangles * 3, context.UNSIGNED_SHORT, firstIndex);
    }

    inline function getUniformLocation(name:String):Null<GLUniformLocation> return uniformLocations[name];

    inline function getAttribsLocation(name:String):Null<Int> return attribsLocations[name];

    override function checkContext() {
        if (context.isContextLost()) {
            context = GL.context;
            repopulateVecFunctions();
        }
    }

    function repopulateVecFunctions() {
        floatVecFuncs = [
            1 => context.uniform1fv,
            2 => context.uniform2fv,
            3 => context.uniform3fv,
            4 => context.uniform4fv,
        ];

        intVecFuncs = [
            1 => context.uniform1iv,
            2 => context.uniform2iv,
            3 => context.uniform3iv,
            4 => context.uniform4iv,
        ];
    }
}
