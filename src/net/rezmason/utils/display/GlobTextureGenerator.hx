package net.rezmason.utils.display;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.display.GradientType;
import flash.filters.BlurFilter;
import flash.geom.Matrix;

class GlobTextureGenerator {

    public static function makeTexture(size:Int, cbk:BitmapData->Void):Void {
        var glob:Shape = new Shape();

        var mat:Matrix = new Matrix();
        mat.tx = mat.ty = size / 2;
        var bmd:BitmapData = new BitmapData(size, size, false, 0x0);
        
        glob.graphics.clear();
        for (ike in 0...1000) {
            var theta:Float = Math.random() * Math.PI * 2;
            var rad:Float = Math.pow(Math.random(), 0.5) * 0.5 * size;

            glob.graphics.beginFill(0x00FF00);
            glob.graphics.drawCircle(Math.cos(theta) * rad, Math.sin(theta) * rad, Math.random() * size / 100);
            glob.graphics.endFill();
        }
        bmd.draw(glob, mat, null, BlendMode.ADD);

        bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft, new BlurFilter(10, 10, 3));

        var grad:Matrix = new Matrix();
        glob.graphics.clear();
        grad.createGradientBox(size, size, 0, -size / 2, -size / 2);
        glob.graphics.beginGradientFill(GradientType.RADIAL, [0x00, 0x00, 0x00, 0x00], [1, 0, 0, 1], [0x00, 0x80, 0xEE, 0xFF], grad);
        glob.graphics.drawRect(-size, -size, size * 2, size * 2);
        glob.graphics.endFill();
        bmd.draw(glob, mat);

        cbk(bmd);
    }
}
