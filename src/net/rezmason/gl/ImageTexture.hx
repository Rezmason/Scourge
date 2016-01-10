package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

import lime.graphics.opengl.GL;
import lime.graphics.PixelFormat;

class ImageTexture extends Texture {

    public var image(default, null):Image;
    var width:Int = -1;
    var height:Int = -1;

    public function new(image:Image):Void {
        super();
        format = UNSIGNED_BYTE;
        this.image = image;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        nativeTexture = GL.createTexture();
        update();
    }

    public inline function update():Void {
        var sizeChanged = nativeTexture == null || width != image.width || height != image.height;
        width = image.width;
        height = image.height;
        if (isConnectedToContext()) {
            GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
            // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
            // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
            
            image.format = PixelFormat.RGBA32;
            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, image.width, image.height, 0, GL.RGBA, format, image.data);
            image.format = PixelFormat.BGRA32;
            
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
            GL.bindTexture(GL.TEXTURE_2D, null);
        }
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        nativeTexture = null;
        width = -1;
        height = -1;
    }
}
