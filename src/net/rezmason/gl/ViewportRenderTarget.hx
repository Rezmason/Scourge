package net.rezmason.gl;

import lime.graphics.opengl.GL;

class ViewportRenderTarget extends RenderTarget {

    var width:Int;
    var height:Int;

    public function new() super();

    public function resize(width:Int, height:Int) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;
            GL.viewport(0, 0, width, height);
        }
    }
}
