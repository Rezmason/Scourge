package net.rezmason.gl;

import flash.display.BitmapData;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

#if !flash
    import openfl.gl.GL;
#end

class BitmapDataTexture extends Texture {

    #if flash
        var nativeTexture:NativeTexture;
    #else
        var bitmapData:BitmapData;
    #end

    public function new(context:Context, bitmapData:BitmapData):Void {
        super();
        #if flash
            var recTex = context.createRectangleTexture(bitmapData.width, bitmapData.height, cast "rgbaHalfFloat", false); // Context3DTextureFormat.RGBA_HALF_FLOAT
            recTex.uploadFromBitmapData(bitmapData);
            nativeTexture = recTex;
        #else
            this.bitmapData = bitmapData;
        #end
    }

    @:allow(net.rezmason.gl)
    override function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {
        if (index != -1) {
            #if flash
                prog.setTextureAt(location, nativeTexture);
            #else
                GL.activeTexture(GL.TEXTURE0 + index);
                GL.bindBitmapDataTexture(bitmapData);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                GL.uniform1i(location, index);
            #end
        }
    }
}
