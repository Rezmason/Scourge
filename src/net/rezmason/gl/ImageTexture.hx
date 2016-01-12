package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.PixelFormat;
import lime.graphics.Image;

class ImageTexture extends Texture {

    public var image(default, null):Image;
    var width:Int = -1;
    var height:Int = -1;

    public function new(image:Image):Void {
        format = UNSIGNED_BYTE;
        this.image = image;
    
        nativeTexture = GL.createTexture();
        update();
    }

    public inline function update():Void {
        var sizeChanged = nativeTexture == null || width != image.width || height != image.height;
        width = image.width;
        height = image.height;
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
