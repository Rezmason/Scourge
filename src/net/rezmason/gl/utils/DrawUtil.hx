package net.rezmason.gl.utils;

import flash.display.BitmapData;
#if flash
    import flash.events.Event;
#end
import flash.geom.Rectangle;
import openfl.gl.GL;

import net.rezmason.gl.utils.Util;
import net.rezmason.gl.Data;

using Lambda;

class DrawUtil extends Util {

    var renderCalls:Array<Int->Int->Void>;

    #if flash
        var stageRect:Rectangle;
    #end

    public function new(view:View, context:Context):Void {
        super(view, context);
        renderCalls = [];

        #if flash
            stageRect = new Rectangle(0, 0, 1, 1);
            view.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            view.addEventListener(Event.RESIZE, onResize);
        #else
            view.render = onRender;
        #end
    }

    public inline function addRenderCall(func:Int->Int->Void):Void { renderCalls.push(func); }

    public inline function removeRenderCall(func:Int->Int->Void):Void { renderCalls.remove(func); }

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
            context.drawTriangles(indexBuffer, firstIndex, numTriangles);
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
                case TEXTURE: // context.setRenderToTexture(outputBuffer.texture);
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
            GL.readPixels(0, 0, outputBuffer.width, outputBuffer.height, GL.RGBA, GL.UNSIGNED_BYTE, data);
        #end
    }

    function onRender(rect:Rectangle):Void {
        var w:Int = Std.int(rect.width);
        var h:Int = Std.int(rect.height);
        for (func in renderCalls) func(w, h);
    }

    #if flash
    function onResize(event:Event):Void {
        stageRect.width = view.stageWidth;
        stageRect.height = view.stageHeight;
    }

    function onEnterFrame(event:Event):Void {
        onRender(stageRect);
    }
    #end
}
