package net.rezmason.gl.capabilities;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.WebGLContext;
import lime.utils.UInt16Array;
import net.rezmason.gl.DataType;
import net.rezmason.gl.PixelFormat;

class UploadHalfFloatTextureProbe extends Probe {

    override function test() {

        var context:WebGLContext = GL.context;

        // As of September 19, 2016, the following rigmarole is Safari's fault.
        var data = new UInt16Array(1);
        var format = TextureFormatTable.getFormat(HALF_FLOAT, SINGLE_CHANNEL);
        for (extension in format.extensions) context.getExtension(extension);
        var texture = context.createTexture();
        var oldUnpackAlignment = context.getParameter(context.UNPACK_ALIGNMENT);
        context.pixelStorei(context.UNPACK_ALIGNMENT, format.unpackAlignment);
        context.bindTexture(context.TEXTURE_2D, texture);
        context.texImage2D(context.TEXTURE_2D, 0, format.dataFormat, 1, 1, 0, SINGLE_CHANNEL, HALF_FLOAT, data);
        context.bindTexture(context.TEXTURE_2D, null);
        context.pixelStorei(context.UNPACK_ALIGNMENT, oldUnpackAlignment);
        context.deleteTexture(texture);
        var isSupported = context.getError() == 0;
        #if js 
            if (!isSupported) js.Browser.console.log('Can\'t upload half float textures. This is Safari, isn\'t it.');
        #end
        return isSupported;
    }
}
