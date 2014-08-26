package net.rezmason.utils.display;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.GradientType;
import flash.filters.BlurFilter;
import flash.geom.Matrix;

class MetaballTextureGenerator {

    public static function makeTexture(radius:Float, ratio:Float, blurAmount:Float, cbk:BitmapData->Void):Void {
        var ball:Shape = new Shape();
        var grad:Matrix = new Matrix();
        grad.createGradientBox(radius * 2, radius * 2, 0, -radius, -radius);
        ball.graphics.beginGradientFill(GradientType.RADIAL, [0xFF, 0xFF], [1, 0], [Std.int(0xFF * ratio), 0xFF], grad);
        ball.graphics.drawCircle(0, 0, radius);
        ball.graphics.endFill();

        var size:Int = Std.int((radius + blurAmount) * 2);
        var mat:Matrix = new Matrix();
        mat.tx = mat.ty = size / 2;
        var bmd:BitmapData = new BitmapData(size, size, false, 0x0);
        bmd.draw(ball, mat);
        bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft, new BlurFilter(blurAmount, blurAmount, 3));
        cbk(bmd);
    }
}
