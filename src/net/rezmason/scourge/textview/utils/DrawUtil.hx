package net.rezmason.scourge.textview.utils;

import flash.display.BitmapData;
// import flash.display3D.IndexBuffer3D;
import flash.geom.Rectangle;

import openfl.display.OpenGLView;

using Lambda;

class DrawUtil extends Util {

    var renderCalls:Array<Rectangle->Void>;

    public function new(view:OpenGLView):Void {
        super(view);
        //view.render = onRender;
        renderCalls = [];
    }

    public function addRenderCall(func:Rectangle->Void):Void { renderCalls.push(func); }

    public function removeRenderCall(func:Rectangle->Void):Void { renderCalls.remove(func); }

    /*
    public function resize(width:Int, height:Int):Void {
        context.configureBackBuffer(width, height, 2, true);
    }

    public function clear(color:Int = 0x0, alpha:Float = 1):Void {
        var red:Int   = (color >> 16) & 0xFF;
        var green:Int = (color >>  8) & 0xFF;
        var blue:Int  = (color >>  0) & 0xFF;
        context.clear(red / 0xFF, green / 0xFF, blue / 0xFF, alpha);
    }

    public function setScissorRectangle(rectangle:Rectangle):Void {
        context.setScissorRectangle(rectangle);
    }

    public function drawTriangles(indexBuffer:IndexBuffer3D, ?firstIndex:Int, ?numTriangles:Int):Void {
        context.drawTriangles(indexBuffer, firstIndex, numTriangles);
    }

    public function present():Void {
        context.present();
    }

    public function drawToBitmapData(destination:BitmapData):Void {
        context.drawToBitmapData(destination);
    }
    */

    function onRender(rect:Rectangle):Void {
        for (func in renderCalls) func(rect);
    }

}
