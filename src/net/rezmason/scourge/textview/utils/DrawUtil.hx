package net.rezmason.scourge.textview.utils;

import flash.display.BitmapData;
import flash.display3D.IndexBuffer3D;
import flash.geom.Rectangle;

class DrawUtil extends Util {

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

}
