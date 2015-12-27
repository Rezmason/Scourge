package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if ogl
    import lime.graphics.opengl.GL;
#end

class TextureOutputBuffer extends OutputBuffer {

    public var texture(default, null):BufferTexture;

    function new():Void {
        super();
        texture = new BufferTexture(FLOAT);
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        texture.connectToContext(context);
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        texture.disconnectFromContext();
    }

    override public function resize(width:Int, height:Int):Bool {
        if (!super.resize(width, height)) return false;
        texture.resize(width, height);
        return true;
    }

    override function activate():Void {
        #if ogl
            GL.bindFramebuffer(GL.FRAMEBUFFER, texture.frameBuffer);
        #end
    }
}
