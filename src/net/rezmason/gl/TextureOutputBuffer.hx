package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if !flash
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

    @:allow(net.rezmason.gl)
    override function activate():Void {
        #if flash
            context.setRenderToTexture(texture.nativeTexture);
        #else
            GL.bindFramebuffer(GL.FRAMEBUFFER, texture.frameBuffer);
        #end
    }
}
