package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if ogl
    import lime.graphics.opengl.GL;
#end

class ViewportRenderTarget extends RenderTarget {

    override public function connectToContext(context:Context):Void {
        super.connectToContext(context);
        if (width * height > 0) {
            #if ogl
                GL.viewport(0, 0, width, height);
            #end
        }
    }

    override public function resize(width:Int, height:Int):Bool {

        if (!super.resize(width, height)) return false;

        if (isConnectedToContext()) {
            #if ogl
                GL.viewport(0, 0, width, height);
            #end
        }

        return true;
    }

    override function activate():Void {
        #if ogl
            GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        #end
    }
}
