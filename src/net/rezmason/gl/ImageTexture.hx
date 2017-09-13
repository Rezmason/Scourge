package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.PixelFormat;
import lime.graphics.Image;

class ImageTexture extends Texture {

    public var image(default, null):Image;
    var width:Int = -1;
    var height:Int = -1;

    public function new(image:Image):Void {
        dataType = UNSIGNED_BYTE;
        pixelFormat = RGBA;
        var format = TextureFormatTable.getFormat(dataType, pixelFormat);
        super(format.extensions);
        dataFormat = format.dataFormat;
        this.image = image;
    
        nativeTexture = context.createTexture();
        update();
    }

    public inline function update():Void {
        checkContext();
        var sizeChanged = nativeTexture == null || width != image.width || height != image.height;
        width = image.width;
        height = image.height;
        context.bindTexture(GL.TEXTURE_2D, nativeTexture);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        
        image.format = PixelFormat.RGBA32;
        context.texImage2D(GL.TEXTURE_2D, 0, dataFormat, image.width, image.height, 0, pixelFormat, dataType, image.data);
        image.format = PixelFormat.BGRA32;
        
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        context.bindTexture(GL.TEXTURE_2D, null);
    }
}
