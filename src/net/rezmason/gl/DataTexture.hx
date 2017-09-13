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
        var oldUnpackAlignment = context.getParameter(context.UNPACK_ALIGNMENT);
        context.pixelStorei(context.UNPACK_ALIGNMENT, unpackAlignment);
        context.bindTexture(context.TEXTURE_2D, nativeTexture);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_WRAP_S, context.CLAMP_TO_EDGE);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_WRAP_T, context.CLAMP_TO_EDGE);
        context.texImage2D(context.TEXTURE_2D, 0, dataFormat, width, height, 0, pixelFormat, dataType, data);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_MAG_FILTER, context.LINEAR);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_MIN_FILTER, context.LINEAR);
        context.bindTexture(context.TEXTURE_2D, null);
        context.pixelStorei(context.UNPACK_ALIGNMENT, oldUnpackAlignment);
    }
}
