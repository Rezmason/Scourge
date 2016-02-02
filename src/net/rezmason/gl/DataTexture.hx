package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.utils.ArrayBufferView;

class DataTexture extends Texture {

    public var data(default, null):ArrayBufferView;
    public var width:Int = -1;
    public var height:Int = -1;
    
    public function new(width:Int, height:Int, format:PixelFormat, type:DataType, data:ArrayBufferView):Void {
        this.width = width;
        this.height = height;
        this.format = format;
        this.type = type;
        this.data = data;
    
        nativeTexture = GL.createTexture();
        GL.getExtension('OES_texture_float');
        GL.getExtension('OES_texture_float_linear');
        update();
    }

    inline function update():Void {
        var sizeChanged = nativeTexture == null;
        GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, format, width, height, 0, format, type, data);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.bindTexture(GL.TEXTURE_2D, null);
    }
}
