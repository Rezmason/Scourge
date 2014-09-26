package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if !flash
    import openfl.gl.GL;
#end

class ViewportOutputBuffer extends OutputBuffer {

    override public function connectToContext(context:Context):Void {
        super.connectToContext(context);
        if (width * height > 0) {
            #if flash
                context.configureBackBuffer(width, height, 2, true);
            #else
                GL.viewport(0, 0, width, height);
            #end
        }
    }

    override public function resize(width:Int, height:Int):Bool {

        if (!super.resize(width, height)) return false;

        if (isConnectedToContext()) {
            #if flash
                context.configureBackBuffer(width, height, 2, true);
            #else
                GL.viewport(0, 0, width, height);
            #end
        }

        return true;
    }

    @:allow(net.rezmason.gl)
    override function activate():Void {
        #if flash
            context.setRenderToBackBuffer();
        #else
            GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        #end
    }

    @:allow(net.rezmason.gl)
    override function deactivate():Void {
        #if flash
            context.present();
        #end
    }
}
