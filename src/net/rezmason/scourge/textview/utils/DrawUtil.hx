package net.rezmason.scourge.textview.utils;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import openfl.display.OpenGLView;
import openfl.gl.GL;

import net.rezmason.scourge.textview.core.Types;

using Lambda;

class DrawUtil extends Util {

    var renderCalls:Array<Int->Int->Void>;

    public function new(view:OpenGLView):Void {
        super(view);
        renderCalls = [];
        view.render = onRender;
    }

    public inline function addRenderCall(func:Int->Int->Void):Void { renderCalls.push(func); }

    public inline function removeRenderCall(func:Int->Int->Void):Void { renderCalls.remove(func); }

    public inline function resize(width:Int, height:Int):Void {
        GL.viewport(0, 0, width, height);
    }

    public inline function clear(color:Int = 0x0, alpha:Float = 1):Void {
        setScissorRectangle(null);

        var red:Float   = ((color >> 16) & 0xFF) / 0xFF;
        var green:Float = ((color >>  8) & 0xFF) / 0xFF;
        var blue:Float  = ((color >>  0) & 0xFF) / 0xFF;

        GL.clearColor(red, green, blue, alpha);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    }

    public inline function setScissorRectangle(rectangle:Rectangle):Void {
        if (rectangle != null) {
            GL.scissor(Std.int(rectangle.x), Std.int(rectangle.y), Std.int(rectangle.width), Std.int(rectangle.height));
            GL.enable(GL.SCISSOR_TEST);
        } else {
            GL.disable(GL.SCISSOR_TEST);
        }
    }

    public inline function drawTriangles(indexBuffer:IndexBuffer, firstIndex:Int = 0, numTriangles:Int = 0):Void {
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.buf);
        GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
    }

    public inline function present():Void {

    }

    public inline function readBack(width:Int, height:Int, data:ReadbackData):Void {
        GL.readPixels(0, 0, width, height, GL.RGBA, GL.UNSIGNED_BYTE, data);
    }

    function onRender(rect:Rectangle):Void {
        var w:Int = Std.int(rect.width);
        var h:Int = Std.int(rect.height);
        for (func in renderCalls) func(w, h);
    }

}
