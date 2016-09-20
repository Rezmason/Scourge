package net.rezmason.gl.capabilities;

import lime.graphics.opengl.GL;
import lime.utils.UInt16Array;
import net.rezmason.gl.DataType;
import net.rezmason.gl.PixelFormat;

class UploadHalfFloatTextureProbe extends Probe {

    override function test() {
        // As of September 19, 2016, the following rigmarole is Safari's fault.
        var data = new UInt16Array(1);
        var format = TextureFormatTable.getFormat(HALF_FLOAT, SINGLE_CHANNEL);
        for (extension in format.extensions) GL.getExtension(extension);
        var texture = GL.createTexture();
        var oldUnpackAlignment = GL.getParameter(GL.UNPACK_ALIGNMENT);
        GL.pixelStorei(GL.UNPACK_ALIGNMENT, format.unpackAlignment);
        GL.bindTexture(GL.TEXTURE_2D, texture);
        GL.texImage2D(GL.TEXTURE_2D, 0, format.dataFormat, 1, 1, 0, SINGLE_CHANNEL, HALF_FLOAT, data);
        GL.bindTexture(GL.TEXTURE_2D, null);
        GL.pixelStorei(GL.UNPACK_ALIGNMENT, oldUnpackAlignment);
        GL.deleteTexture(texture);
        var isSupported = GL.getError() == 0;
        #if js 
            if (!isSupported) js.Browser.console.log('Can\'t upload half float textures. This is Safari, isn\'t it.');
        #end
        return isSupported;
    }
}
