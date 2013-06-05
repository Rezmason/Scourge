package net.rezmason.gl;

import openfl.gl.GL;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLRenderbuffer;
import openfl.gl.GLTexture;

class OutputBuffer {

    @:allow(net.rezmason.gl) var frameBuffer:GLFramebuffer;
    var texture:GLTexture;
    var renderBuffer:GLRenderbuffer;

    public function new(?empty:Bool):Void {

        if (!empty) {
            frameBuffer = GL.createFramebuffer();
            texture = GL.createTexture();
            renderBuffer = GL.createRenderbuffer();
        }
    }

    public function resize(width:Int, height:Int):Void {

        if (frameBuffer == null) {
            GL.viewport(0, 0, width, height);
        } else {
            GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);

            GL.bindTexture(GL.TEXTURE_2D, texture);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);

            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

            GL.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
            GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);

            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
            GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

            GL.bindTexture(GL.TEXTURE_2D, null);
            GL.bindRenderbuffer(GL.RENDERBUFFER, null);
            GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        }
    }
}
