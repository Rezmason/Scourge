package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLFramebuffer;

class RenderTarget extends Artifact {
    @:allow(net.rezmason.gl) var frameBuffer:GLFramebuffer;
    function new() {}
    public function bind() GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
}
