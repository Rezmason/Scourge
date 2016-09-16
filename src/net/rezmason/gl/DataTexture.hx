package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.utils.ArrayBufferView;

class DataTexture extends Texture {

    public var data(default, null):ArrayBufferView;
    public var width:Int = -1;
    public var height:Int = -1;
    var unpackAlignment:UInt;
    
    public function new(width:Int, height:Int, pixelFormat:PixelFormat, dataType:DataType, data:ArrayBufferView):Void {
        this.dataType = dataType;
        this.pixelFormat = pixelFormat;
        var format = TextureFormatTable.getFormat(dataType, pixelFormat);
        super(format.extensions);
        dataFormat = format.dataFormat;
        unpackAlignment = format.unpackAlignment;
        this.width = width;
        this.height = height;
        this.data = data;
    
        nativeTexture = GL.createTexture();
        update();
    }

    inline function update():Void {
        var oldUnpackAlignment = GL.getParameter(GL.UNPACK_ALIGNMENT);
        GL.pixelStorei(GL.UNPACK_ALIGNMENT, unpackAlignment);
        GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, dataFormat, width, height, 0, pixelFormat, dataType, data);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.bindTexture(GL.TEXTURE_2D, null);
        GL.pixelStorei(GL.UNPACK_ALIGNMENT, oldUnpackAlignment);
    }
}
