package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.TextureFormat;

#if ogl
    import lime.graphics.opengl.GL;
    import lime.graphics.opengl.GLFramebuffer;
    import lime.graphics.opengl.GLRenderbuffer;
#end

@:allow(net.rezmason.gl)
class BufferTexture extends Texture {

    var format:TextureFormat;
    var width:Int;
    var height:Int;
    #if ogl
        var frameBuffer:GLFramebuffer;
        var renderBuffer:GLRenderbuffer;
    #end

    function new(format:TextureFormat):Void {
        super();
        this.format = format;
        width = 1;
        height = 1;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if ogl
            nativeTexture = GL.createTexture();
            frameBuffer = GL.createFramebuffer();
            renderBuffer = GL.createRenderbuffer();
        #end

        resize(width, height);
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if ogl
            frameBuffer = null;
            renderBuffer = null;
        #end
        
        nativeTexture = null;
    }

    function resize(width:Int, height:Int):Void {
        if (width  < 1) width = 1;
        if (height < 1) height = 1;
        this.width = width;
        this.height = height;
        if (isConnectedToContext()) {
            #if ogl
                GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);

                GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

                GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, format, null);

                GL.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
                GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);

                GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, nativeTexture, 0);
                GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

                GL.bindTexture(GL.TEXTURE_2D, null);
                GL.bindRenderbuffer(GL.RENDERBUFFER, null);
                GL.bindFramebuffer(GL.FRAMEBUFFER, null);
            #end
        }
    }
}
