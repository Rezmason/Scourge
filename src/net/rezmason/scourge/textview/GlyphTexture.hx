package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.display3D.Context3D;
import nme.display3D.Context3DTextureFormat;
import nme.display3D.textures.Texture;
import nme.filters.BitmapFilterQuality;
import nme.filters.GlowFilter;
import nme.geom.Matrix;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var scaleX(default, null):Float;
    public var scaleY(default, null):Float;

    public function new(context:Context3D, src:BitmapData):Void {

        var width:Int = largestPowerOfTwo(src.width);
        var height:Int = largestPowerOfTwo(src.height);

        scaleX = src.width  / width;
        scaleY = src.height / height;

        texture = context.createTexture(width, width, Context3DTextureFormat.BGRA, false);

        var bmd:BitmapData = new BitmapData(width, width, true, 0x0);
        //bmd.copyPixels(src, src.rect, bmd.rect.topLeft);
        bmd.fillRect(bmd.rect, 0xFFFFFFFF);
        bmd.copyChannel(src, src.rect, bmd.rect.topLeft, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
        //*
        bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft,
            new GlowFilter(
                0xFF000000,
                1.0,
                5,
                5,
                1,
                BitmapFilterQuality.HIGH,
                true
            )
        );
        /**/
        //stage.addChild(new Bitmap(bmd));

        var lev:Int = 0;
        while (width > 0) {
            texture.uploadFromBitmapData(getResizedBitmapData(bmd, width), lev);
            lev++;
            width = Std.int(width / 2);
        }
    }

    inline function largestPowerOfTwo(input:Int):Int {
        var output:Int = 1;
        while (output < input) output = output * 2;
        return output;
    }

    inline function getResizedBitmapData(bmp:BitmapData, width:UInt):BitmapData {
        var mat:Matrix = new Matrix();
        mat.scale(width / bmp.width, width / bmp.width);

        var bd:BitmapData = new BitmapData(width, width, bmp.transparent, 0x00FFFFFF);
        bd.draw(bmp, mat);

        return bd;
    }

}
