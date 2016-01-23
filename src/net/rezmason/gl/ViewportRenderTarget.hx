package net.rezmason.gl;

import lime.graphics.opengl.GL;

class ViewportRenderTarget extends RenderTarget {

    public function new() super();

    public function resize(width:Int, height:Int) {
        _width = width;
        _height = height;
    }
}
