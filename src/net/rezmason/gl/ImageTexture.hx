package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if !flash
    import lime.graphics.opengl.GL;
    import lime.graphics.PixelFormat;
#end

class ImageTexture extends Texture {

    var image:Image;
    var nativeTexture:NativeTexture;

    public function new(image:Image):Void {
        super();
        this.image = image;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if flash
            var recTex = context.createRectangleTexture(image.width, image.height, cast "rgbaHalfFloat", false); // Context3DTextureFormat.RGBA_HALF_FLOAT
            var bmd = @:privateAccess image.buffer.__srcBitmapData;
            recTex.uploadFromBitmapData(bmd);
            nativeTexture = recTex;
        #else
            nativeTexture = GL.createTexture();
            GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
            
            var tempImage = image.clone();
            tempImage.format = PixelFormat.RGBA32;
            var pixelData = tempImage.data;
            
            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, image.width, image.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelData);
            
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
