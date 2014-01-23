package net.rezmason.gl.utils;

import flash.display.BitmapData;
#if flash
    import flash.display3D.Context3DTextureFormat;
#end
import flash.geom.Matrix;
import net.rezmason.gl.Data;
import net.rezmason.gl.utils.Util;

class TextureUtil extends Util {

    public inline function createTexture(src:BitmapData):Texture {
        #if flash
            var size:Int = src.width;
            var texture:Texture = context.createTexture(size, size, Context3DTextureFormat.BGRA, false);

            /*
            var lev:Int = 0;
            while (size > 0) {
                var bmp:BitmapData = getResizedBitmapData(src, size);
                texture.uploadFromBitmapData(bmp, lev);
                bmp.dispose();
                lev++;
                size = Std.int(size / 2);
            }
            */

            texture.uploadFromBitmapData(src);

            return texture;
        #else
            return src;
        #end
    }

    inline function getResizedBitmapData(bmp:BitmapData, width:UInt):BitmapData {
        var mat:Matrix = new Matrix();
        mat.scale(width / bmp.width, width / bmp.width);

        var bd:BitmapData = new BitmapData(width, width, bmp.transparent, 0x00FFFFFF);
        bd.draw(bmp, mat);

        return bd;
    }
}
