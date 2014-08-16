package net.rezmason.utils.display;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.filters.BlurFilter;
import flash.geom.Matrix;

class MetaballTextureGenerator {

    public static function makeTexture(radius:Float, blurAmount:Float, cbk:BitmapData->Void):Void {
        var ball:Shape = new Shape();
        ball.graphics.beginFill(0xFF);
        ball.graphics.drawCircle(0, 0, radius);
        ball.graphics.endFill();

        var size:Int = largestPowerOfTwo(Std.int((radius + blurAmount) * 2));
        var mat:Matrix = new Matrix();
        mat.tx = mat.ty = size / 2;
        var bmd:BitmapData = new BitmapData(size, size, false, 0x0);
        bmd.draw(ball, mat);
        bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft, new BlurFilter(blurAmount, blurAmount, 3));
        cbk(bmd);
    }

    inline static function largestPowerOfTwo(input:Int):Int {
        var output:Int = 1;
        while (output < input) output = output * 2;
        return output;
    }
}
