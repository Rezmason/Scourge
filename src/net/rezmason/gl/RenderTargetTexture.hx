package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLFramebuffer;
import lime.utils.ArrayBufferView;

class RenderTargetTexture extends Texture {

    public var renderTarget(default, null):RenderTarget;
    public var width(default, null):Int;
    public var height(default, null):Int;
    var frameBuffer:GLFramebuffer;

    public function new(type:DataType):Void {
        this.type = type;
        format = RGBA;
        width = 1;
        height = 1;
        renderTarget = new RenderTarget();
    
        nativeTexture = GL.createTexture();
        frameBuffer = GL.createFramebuffer();
        renderTarget.frameBuffer = frameBuffer;
        renderTarget._width = width;
        renderTarget._height = height;
        resize(width, height);
    }

    public function resize(width:Int, height:Int):Void {
        if (width  < 1) width = 1;
        if (height < 1) height = 1;
        this.width = width;
        this.height = height;
        renderTarget._width = width;
        renderTarget._height = height;
        GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
        GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, format, width, height, 0, format, type, null);
        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, nativeTexture, 0);
        GL.bindTexture(GL.TEXTURE_2D, null);
        GL.bindRenderbuffer(GL.RENDERBUFFER, null);
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
    }

    public function readBack(data:ArrayBufferView):Void {
        GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
        GL.readPixels(0, 0, width, height, GL.RGBA, type, data);
    }
}
