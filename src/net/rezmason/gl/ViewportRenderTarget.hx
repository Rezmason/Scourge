package net.rezmason.gl;

import lime.graphics.opengl.GL;

class ViewportRenderTarget extends RenderTarget {

    var width:Int;
    var height:Int;

    override public function connectToContext(context) {
        super.connectToContext(context);
        setSize(width, height);
    }

    public function resize(width:Int, height:Int) {
        if ((this.width != width || this.height != height) && isConnectedToContext()) {
            setSize(width, height);
        }
    }

    inline function setSize(width, height) {
        this.width = width;
        this.height = height;
        GL.viewport(0, 0, width, height);
    }
}
