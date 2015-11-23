package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if flash
    import flash.Lib;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProfile;
    import flash.display3D.Context3DRenderMode;
    import flash.display3D.Context3DTextureFormat;
    import flash.events.Event;
#else
    import lime.graphics.Renderer;
    import lime.graphics.opengl.GL;
#end

class GLSystem {

    public var connected(default, null):Bool;
    public var onConnected:Void->Void;

    var context:Context;
    var artifacts:Array<Artifact>;

    public var currentOutputBuffer(default, null):OutputBuffer;
    public var viewportOutputBuffer(get, null):ViewportOutputBuffer;
    
    public function new():Void {
        connected = false;
        artifacts = [];
    }

    public function connect():Void {
        if (!connected) init();
        else onInit();
    }

    function init():Void {
        #if flash
            var stage = Lib.current.stage;
            var stage3D = stage.stage3Ds[0];
            if (stage3D.context3D != null) {
                context = stage3D.context3D;
                onInit();
            } else {
                function onCreate(event:Event):Void {
                    event.target.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);
                    context = stage.stage3Ds[0].context3D;
                    onInit();
                }
                stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
                stage3D.requestContext3D(cast Context3DRenderMode.AUTO, cast 'standard'); // Context3DProfile.STANDARD
            }
        #else
            context = GL;
            onInit();
        #end
    }

    function onInit():Void {
        for (artifact in artifacts) {
            if (artifact.isDisposed) artifacts.remove(artifact);
            else artifact.connectToContext(context);
        }
        connected = true;
        if (onConnected != null) onConnected();
    }

    public function disconnect():Void {
        #if flash context.dispose(); #end
        context = null;

        connected = false;
        for (artifact in artifacts) {
            if (artifact.isDisposed) artifacts.remove(artifact);
            else artifact.disconnectFromContext();
        }
    }

    inline function registerArtifact<T:(Artifact)>(artifact:T):T {
        if (artifacts.indexOf(artifact) == -1) {
            artifacts.push(artifact);
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

    public inline function createTextureOutputBuffer():TextureOutputBuffer {
        return registerArtifact(new TextureOutputBuffer());
    }

    public inline function createReadbackOutputBuffer():ReadbackOutputBuffer {
        return registerArtifact(new ReadbackOutputBuffer());
    }
    
    public inline function createImageTexture(img:Image):ImageTexture {
        return registerArtifact(new ImageTexture(img));
    }

    public inline function setProgram(program:Program):Void {
        #if flash 
            program.prog.attach();
        #else 
            GL.useProgram(program.prog);
        #end
    }

    public inline function setBlendFactors(sourceFactor:BlendFactor, destinationFactor:BlendFactor):Void {
        #if flash
            context.setBlendFactors(sourceFactor, destinationFactor);
        #else
            GL.enable(GL.BLEND);
            GL.blendFunc(sourceFactor, destinationFactor);
        #end
    }

    public inline function setDepthTest(enabled:Bool):Void {
        #if flash
            context.setDepthTest(enabled, Context3DCompareMode.LESS);
        #else
            if (enabled) GL.enable(GL.DEPTH_TEST);
            else GL.disable(GL.DEPTH_TEST);
        #end
    }

    public inline function enableExtension(extName:String):Void {
        #if !flash
            GL.getExtension(extName);
        #end
    }

    public inline function clear(red:Float, green:Float, blue:Float, alpha:Float = 1):Void {
        #if flash
            context.clear(red, green, blue, alpha);
        #else
            GL.clearColor(red, green, blue, alpha);
            GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        #end
    }

    public inline function draw(indexBuffer:IndexBuffer, firstIndex:UInt = 0, numTriangles:UInt = 0):Void {
        #if flash
            context.drawTriangles(indexBuffer.buf, firstIndex, numTriangles);
        #else
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.buf);
            GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        #end
    }

    public inline function start(outputBuffer:OutputBuffer):Void {
        if (currentOutputBuffer != outputBuffer) {
            currentOutputBuffer = outputBuffer;
            outputBuffer.activate();
        }
    }

    public inline function finish():Void {
        if (currentOutputBuffer != null) {
            currentOutputBuffer.deactivate();
            currentOutputBuffer = null;
        }
    }

    inline function get_viewportOutputBuffer():ViewportOutputBuffer {
        if (viewportOutputBuffer == null) {
            viewportOutputBuffer = registerArtifact(new ViewportOutputBuffer());
        }
        return viewportOutputBuffer;
    }
}
