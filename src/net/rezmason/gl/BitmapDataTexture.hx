package net.rezmason.gl;

import flash.display.BitmapData;
import net.rezmason.gl.GLTypes;

#if !flash
    import openfl.gl.GL;
#end

class BitmapDataTexture extends Texture {

    var bitmapData:BitmapData;
    #if flash
        var nativeTexture:NativeTexture;
    #end

    public function new(bitmapData:BitmapData):Void {
        this.bitmapData = bitmapData;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash
            var recTex = context.createRectangleTexture(bitmapData.width, bitmapData.height, cast "rgbaHalfFloat", false); // Context3DTextureFormat.RGBA_HALF_FLOAT
            recTex.uploadFromBitmapData(bitmapData);
            nativeTexture = recTex;
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
