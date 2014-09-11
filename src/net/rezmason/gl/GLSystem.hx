package net.rezmason.gl;

import flash.display.BitmapData;
import flash.display.Stage;
import flash.geom.Rectangle;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

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

    var cbk:Void->Void;
    var view:View;
    var context:Context;
    #if flash var stageRect:Rectangle; #end

    public function new(stage:Stage, cbk:Void->Void):Void {
        this.cbk = cbk;

        #if flash
            view = stage;
            var stage3D = view.stage3Ds[0];
            if (stage3D.context3D != null) {
                context = stage3D.context3D;
                init();
            } else {
                stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
                stage3D.requestContext3D(cast Context3DRenderMode.AUTO, cast "standard"); // Context3DProfile.STANDARD
            }
        #else
            if (View.isSupported) {
                view = new View();
                context = GL;
                stage.addChild(view);
                init();
            } else {
                trace('OpenGLView isn\'t supported.');
            }
        #end
    }

    #if flash
        function onCreate(event:Event):Void {
            event.target.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);
            context = view.stage3Ds[0].context3D;
            init();
        }
    #end

    function init():Void {

        var cbk:Void->Void = this.cbk;
        this.cbk = null;

        #if flash
            stageRect = new Rectangle(0, 0, 1, 1);
            view.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            view.addEventListener(Event.RESIZE, onResize);
        #else
            view.render = handleRender;
        #end

        haxe.Timer.delay(cbk, 0);
    }

    function handleRender(rect:Rectangle):Void {
        if (onRender != null) onRender(Std.int(rect.width), Std.int(rect.height));
    }

    #if flash
        function onResize(event:Event):Void {
            stageRect.width = view.stageWidth;
            stageRect.height = view.stageHeight;
        }

        function onEnterFrame(event:Event):Void {
            handleRender(stageRect);
        }
    #end

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

    public inline function setProgram(program:Program):Void {
        #if flash program.prog.attach();
        #else GL.useProgram(program.prog);
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

    public inline function drawTriangles(indexBuffer:IndexBuffer, firstIndex:Int = 0, numTriangles:Int = 0):Void {
        #if flash
            context.drawTriangles(indexBuffer.buf, firstIndex, numTriangles);
        #else
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.buf);
            GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        #end
    }

    public inline function createOutputBuffer(type:OutputBufferType):OutputBuffer {
        return new OutputBuffer(type, context);
    }

    public inline function setOutputBuffer(outputBuffer:OutputBuffer):Void {
        #if flash
            switch (outputBuffer.type) {
                case TEXTURE: 
                    switch (outputBuffer.texture) {
                        case TEX(tex): context.setRenderToTexture(tex);
                        case _:
                    }
                case _: context.setRenderToBackBuffer();
            }
        #else
            GL.bindFramebuffer(GL.FRAMEBUFFER, outputBuffer.frameBuffer);
        #end
    }

    public inline function finishOutputBuffer(outputBuffer:OutputBuffer):Void {
        #if flash
            switch (outputBuffer.type) {
                case VIEWPORT: context.present();
                case READBACK: context.drawToBitmapData(outputBuffer.bitmapData);
                case _:
            }
        #end
    }

    public inline function createReadbackData(size:Int = 0):ReadbackData {
        return new ReadbackData(#if !flash size #end);
    }

    public inline function readBack(outputBuffer:OutputBuffer, data:ReadbackData):Void {
        #if flash
            if (outputBuffer.bitmapData != null) {
                var rect:Rectangle = new Rectangle(0, 0, outputBuffer.width, outputBuffer.height);
                data.position = 0;
                outputBuffer.bitmapData.copyPixelsToByteArray(rect, data);
                data.position = 0;
            }
        #else
            setOutputBuffer(outputBuffer);
            GL.readPixels(0, 0, outputBuffer.width, outputBuffer.height, GL.RGBA, outputBuffer.format, data);
        #end
    }

    public inline function createBitmapDataTexture(bmd:BitmapData):Texture {
        #if flash
            var size:Int = bmd.width;
            var tex = context.createRectangleTexture(size, size, cast "rgbaHalfFloat", false); // Context3DTextureFormat.RGBA_HALF_FLOAT
            tex.uploadFromBitmapData(bmd);
            return TEX(tex);
        #else
            return BMD(bmd);
        #end
    }
}
