package net.rezmason.gl;

import flash.display.BitmapData;
import flash.display.Stage;
import flash.geom.Rectangle;
import flash.Lib;

import net.rezmason.gl.GLTypes;

#if flash
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProfile;
    import flash.display3D.Context3DRenderMode;
    import flash.display3D.Context3DTextureFormat;
    import flash.events.Event;
#else
    import openfl.gl.GL;
#end

using Lambda;

class GLSystem {

    public var onRender:Int->Int->Void;
    public var onInit:Void->Void;

    public var initialized(default, null):Bool;

    var view:View;
    var context:Context;

    public var currentOutputBuffer(default, null):OutputBuffer;
    public var viewportOutputBuffer(get, null):ViewportOutputBuffer;
    
    public function new():Void {
        initialized = false;
        #if flash
            view = Lib.current.stage;
            var stage3D = view.stage3Ds[0];
            if (stage3D.context3D != null) {
                context = stage3D.context3D;
                init();
            } else {

                function onCreate(event:Event):Void {
                    event.target.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);
                    context = view.stage3Ds[0].context3D;
                    init();
                }

                stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
                stage3D.requestContext3D(cast Context3DRenderMode.AUTO, cast "standard"); // Context3DProfile.STANDARD
            }
        #else
            if (View.isSupported) {
                view = new View();
                context = GL;
                Lib.current.stage.addChild(view);
                init();
            } else {
                trace('OpenGLView isn\'t supported.');
            }
        #end
    }

    function init():Void {
        initialized = true;
        #if flash
            var stageRect:Rectangle = new Rectangle(0, 0, 1, 1);

            function onEnterFrame(event:Event):Void {
                handleRender(stageRect);
            }

            function onResize(event:Event):Void {
                stageRect.width = view.stageWidth;
                stageRect.height = view.stageHeight;
            }

            view.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            view.addEventListener(Event.RESIZE, onResize);
        #else
            view.render = handleRender;
        #end

        if (onInit != null) onInit();
    }

    function handleRender(rect:Rectangle):Void {
        if (onRender != null) onRender(Std.int(rect.width), Std.int(rect.height));
    }

    public inline function createVertexBuffer(numVertices:Int, footprint:Int, ?usage:BufferUsage):VertexBuffer {
        return new VertexBuffer(context, numVertices, footprint, usage);
    }

    public inline function createIndexBuffer(numIndices:Int, ?usage:BufferUsage):IndexBuffer {
        return new IndexBuffer(context, numIndices, usage);
    }

    public inline function loadProgram(vertSource:String, fragSource:String, onLoaded:Program->Void):Void {
        var program:Program = new Program(context);
        program.load(vertSource, fragSource, function() onLoaded(program));
    }

    public inline function createTextureOutputBuffer():TextureOutputBuffer {
        return new TextureOutputBuffer(context);
    }

    public inline function createReadbackOutputBuffer():ReadbackOutputBuffer {
        return new ReadbackOutputBuffer(context);
    }
    
    public inline function createBitmapDataTexture(bmd:BitmapData):BitmapDataTexture {
        return new BitmapDataTexture(context, bmd);
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

    public inline function clear(color:Int = 0x0, alpha:Float = 1):Void {
        var red:Float   = ((color >> 16) & 0xFF) / 0xFF;
        var green:Float = ((color >>  8) & 0xFF) / 0xFF;
        var blue:Float  = ((color >>  0) & 0xFF) / 0xFF;

        #if flash
            context.clear(red, green, blue, alpha);
        #else
            GL.clearColor(red, green, blue, alpha);
            GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        #end
    }

    public inline function draw(indexBuffer:IndexBuffer, firstIndex:Int = 0, numTriangles:Int = 0):Void {
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

    public inline function get_viewportOutputBuffer():ViewportOutputBuffer {
        if (viewportOutputBuffer == null) viewportOutputBuffer = new ViewportOutputBuffer(context);
        return viewportOutputBuffer;
    }
}
