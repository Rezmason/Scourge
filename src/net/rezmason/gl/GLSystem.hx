package net.rezmason.gl;

import haxe.io.Bytes;
import net.rezmason.gl.GLTypes;

#if ogl
    import lime.graphics.opengl.GL;
    import lime.utils.Float32Array;
    import lime.utils.UInt8Array;
#end

class GLSystem {

    public var connected(default, null):Bool;
    public var onConnected:Void->Void;

    var context:Context;
    var artifacts:Map<UInt, Artifact>;

    public var currentRenderTarget(default, null):RenderTarget;
    public var viewportRenderTarget(get, null):ViewportRenderTarget;
    
    public function new():Void {
        connected = false;
        artifacts = new Map();
    }

    public function connect():Void {
        if (!connected) init();
        else onInit();
    }

    function init():Void {
        #if ogl
            context = GL;
            onInit();
        #end
    }

    function onInit():Void {
        for (artifact in artifacts) {
            if (artifact.isDisposed) artifacts.remove(artifact.id);
            else artifact.connectToContext(context);
        }
        connected = true;
        if (onConnected != null) onConnected();
    }

    public function disconnect():Void {
        context = null;

        connected = false;
        for (artifact in artifacts) {
            if (artifact.isDisposed) artifacts.remove(artifact.id);
            else artifact.disconnectFromContext();
        }
    }

    inline function registerArtifact<T:(Artifact)>(artifact:T):T {
        if (!artifacts.exists(artifact.id)) {
            artifacts.set(artifact.id, artifact);
            if (connected) artifact.connectToContext(context);
        }
        return artifact;
    }

    public inline function createVertexBuffer(numVertices:UInt, footprint:UInt, ?usage:BufferUsage):VertexBuffer {
        return registerArtifact(new VertexBuffer(numVertices, footprint, usage));
    }

    public inline function createIndexBuffer(numIndices:UInt, ?usage:BufferUsage):IndexBuffer {
        return registerArtifact(new IndexBuffer(numIndices, usage));
    }

    public inline function createProgram(vertSource:String, fragSource:String):Program {
        return registerArtifact(new Program(vertSource, fragSource));
    }

    public inline function createRenderTargetTexture(format:TextureFormat):RenderTargetTexture {
        return registerArtifact(new RenderTargetTexture(format));
    }

    public inline function createImageTexture(img:Image):ImageTexture {
        return registerArtifact(new ImageTexture(img));
    }

    public inline function createDataTexture(width:Int, height:Int, format:TextureFormat, data:Data):DataTexture {
        return registerArtifact(new DataTexture(width, height, format, data));
    }

    public inline function createHalfFloatTexture(width:Int, height:Int, bytes:Bytes, ?singleChannel:Bool):HalfFloatTexture {
        return registerArtifact(new HalfFloatTexture(width, height, bytes, singleChannel));
    }

    public inline function createReadbackData(width:Int, height:Int, format:TextureFormat):Data {
        var data:Data = null;
        var len = width * height * 4;
        #if ogl
            switch (format) {
                case FLOAT: data = new Float32Array(len);
                case UNSIGNED_BYTE: data = new UInt8Array(len);
            }
        #end
        return data;
    }

    public inline function setProgram(program:Program):Void {
        #if ogl 
            GL.useProgram(program.prog);
        #end
    }

    public inline function setBlendFactors(sourceFactor:BlendFactor, destinationFactor:BlendFactor):Void {
        #if ogl
            GL.enable(GL.BLEND);
            GL.blendFunc(sourceFactor, destinationFactor);
        #end
    }

    public inline function setDepthTest(enabled:Bool):Void {
        #if ogl
            if (enabled) GL.enable(GL.DEPTH_TEST);
            else GL.disable(GL.DEPTH_TEST);
        #end
    }

    public inline function enableExtension(extName:String):Void {
        #if ogl
            GL.getExtension(extName);
        #end
    }

    public inline function clear(red:Float, green:Float, blue:Float, alpha:Float = 1):Void {
        #if ogl
            GL.clearColor(red, green, blue, alpha);
            GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        #end
    }

    public inline function draw(indexBuffer:IndexBuffer, firstIndex:UInt = 0, numTriangles:UInt = 0):Void {
        #if ogl
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.buf);
            GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        #end
    }

    public inline function start(renderTarget:RenderTarget):Void {
        if (currentRenderTarget != renderTarget) {
            currentRenderTarget = renderTarget;
            #if ogl
                GL.bindFramebuffer(GL.FRAMEBUFFER, renderTarget.frameBuffer);
            #end
        }
    }

    public inline function finish():Void {
        currentRenderTarget = null;
    }

    inline function get_viewportRenderTarget():ViewportRenderTarget {
        if (viewportRenderTarget == null) {
            viewportRenderTarget = registerArtifact(new ViewportRenderTarget());
        }
        return viewportRenderTarget;
    }
}
