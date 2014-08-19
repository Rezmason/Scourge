package net.rezmason.gl.utils;

import flash.display.BitmapData;
#if flash
    import flash.display3D.Context3DTextureFormat;
#end
import flash.geom.Matrix;
import net.rezmason.gl.Data;
import net.rezmason.gl.utils.Util;

class TextureUtil extends Util {

    public inline function createBitmapDataTexture(bmd:BitmapData):Texture {
        #if flash
            var size:Int = bmd.width;
            var tex = context.createRectangleTexture(size, size, Context3DTextureFormat.BGRA, false);
            tex.uploadFromBitmapData(bmd);
            return TEX(tex);
        #else
            return BMD(bmd);
        #end
    }
}
