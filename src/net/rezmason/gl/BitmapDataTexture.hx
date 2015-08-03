package net.rezmason.gl;

import flash.display.BitmapData;
import net.rezmason.gl.GLTypes;

#if !flash
    import openfl.gl.GL;
#end

class BitmapDataTexture extends Texture {

    var bitmapData:BitmapData;
    var nativeTexture:NativeTexture;

    public function new(bitmapData:BitmapData):Void {
        super();
        this.bitmapData = bitmapData;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash
            var recTex = context.createRectangleTexture(bitmapData.width, bitmapData.height, cast "rgbaHalfFloat", false); // Context3DTextureFormat.RGBA_HALF_FLOAT
            recTex.uploadFromBitmapData(bitmapData);
            nativeTexture = recTex;
        #else
            nativeTexture = GL.createTexture();
            GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
            
            var pixelData = @:privateAccess (bitmapData.__image).data;
            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelData);
            
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
            GL.bindTexture(GL.TEXTURE_2D, null);
        #end
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash nativeTexture.dispose(); #end
        nativeTexture = null;
    }

    override function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {
        if (index != -1) {
            #if flash
                prog.setTextureAt(location, nativeTexture);
            #else
                GL.activeTexture(GL.TEXTURE0 + index);
                GL.uniform1i(location, index);
                GL.bindTexture (GL.TEXTURE_2D, nativeTexture);
            #end
        }
    }
}
