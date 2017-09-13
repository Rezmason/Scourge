package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLFramebuffer;
import lime.utils.ArrayBufferView;

class RenderTargetTexture extends Texture {

    public var renderTarget(default, null):RenderTarget;
    public var width(default, null):Int;
    public var height(default, null):Int;
    var frameBuffer:GLFramebuffer;

    public function new(dataType) {
        pixelFormat = RGBA;
        var format = TextureFormatTable.getFormat(dataType, pixelFormat);
        super(format.extensions);
        this.dataType = dataType;
        this.dataFormat = format.dataFormat;
        width = 1;
        height = 1;
        renderTarget = new RenderTarget();
    
        nativeTexture = context.createTexture();
        frameBuffer = context.createFramebuffer();
        renderTarget.frameBuffer = frameBuffer;
        renderTarget._width = width;
        renderTarget._height = height;
        resize(width, height);
    }

    public function resize(width:UInt, height:UInt):Void {
        checkContext();
        if (width  < 1) width = 1;
        if (height < 1) height = 1;
        this.width = width;
        this.height = height;
        renderTarget._width = width;
        renderTarget._height = height;
        context.bindFramebuffer(context.FRAMEBUFFER, frameBuffer);
        context.bindTexture(context.TEXTURE_2D, nativeTexture);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_MAG_FILTER, context.LINEAR);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_MIN_FILTER, context.LINEAR);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_WRAP_S, context.CLAMP_TO_EDGE);
        context.texParameteri(context.TEXTURE_2D, context.TEXTURE_WRAP_T, context.CLAMP_TO_EDGE);
        context.texImage2D(context.TEXTURE_2D, 0, dataFormat, width, height, 0, pixelFormat, dataType, null);
        context.framebufferTexture2D(context.FRAMEBUFFER, context.COLOR_ATTACHMENT0, context.TEXTURE_2D, nativeTexture, 0);
        context.bindTexture(context.TEXTURE_2D, null);
        context.bindRenderbuffer(context.RENDERBUFFER, null);
        context.bindFramebuffer(context.FRAMEBUFFER, null);
    }

    public function readBack(data:ArrayBufferView):Void {
        checkContext();
        context.bindFramebuffer(context.FRAMEBUFFER, frameBuffer);
        context.readPixels(0, 0, width, height, context.RGBA, dataType, data);
    }
}
