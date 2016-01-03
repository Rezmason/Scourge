package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.TextureFormat;

#if ogl
    import lime.graphics.opengl.GL;
#end

class TextureRenderTarget extends RenderTarget {

    public var texture(default, null):BufferTexture;
    var format:TextureFormat;

    function new(format):Void {
        super();
        this.format = format;
        texture = new BufferTexture(format);
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

    public function readBack(data:Data):Void {
        #if ogl
            GL.bindFramebuffer(GL.FRAMEBUFFER, texture.frameBuffer);
            GL.readPixels(0, 0, width, height, GL.RGBA, texture.format, data);
        #end
    }
}
