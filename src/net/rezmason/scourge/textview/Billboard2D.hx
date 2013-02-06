package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.Shape;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.geom.Transform;

class Billboard2D extends Shape {

    public function new(bitmapData:BitmapData, mat:Matrix, rect:Rectangle):Void {
        super();
        if (transform == null) {
            transform = new Transform(this);
        }
        update(bitmapData, mat, rect);
    }

    public function update(bitmapData:BitmapData, mat:Matrix, rect:Rectangle):Void {
        graphics.clear();
        //graphics.lineStyle(0, 0xFFFFFF);
        graphics.beginBitmapFill(bitmapData, mat, false, true);
        graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
        graphics.endFill();
    }

    public function clear():Void {
        graphics.clear();
    }
}
