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
    
        nativeTexture = context.createTexture();
        update();
    }

    inline function update():Void {
        checkContext();
        var oldUnpackAlignment = context.getParameter(GL.UNPACK_ALIGNMENT);
        context.pixelStorei(GL.UNPACK_ALIGNMENT, unpackAlignment);
        context.bindTexture(GL.TEXTURE_2D, nativeTexture);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        context.texImage2D(GL.TEXTURE_2D, 0, dataFormat, width, height, 0, pixelFormat, dataType, data);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        context.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        context.bindTexture(GL.TEXTURE_2D, null);
        context.pixelStorei(GL.UNPACK_ALIGNMENT, oldUnpackAlignment);
    }
}
