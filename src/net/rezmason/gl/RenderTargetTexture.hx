package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if ogl
    import lime.graphics.opengl.GL;
    import lime.graphics.opengl.GLFramebuffer;
#end

class RenderTargetTexture extends Texture {

    public var renderTarget(default, null):RenderTarget;
    public var width(default, null):Int;
    public var height(default, null):Int;
    #if ogl
        var frameBuffer:GLFramebuffer;
    #end

    function new(format:TextureFormat):Void {
        super();
        this.format = format;
        width = 1;
        height = 1;
        renderTarget = new RenderTarget();
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if ogl
            nativeTexture = GL.createTexture();
            frameBuffer = GL.createFramebuffer();
            renderTarget.frameBuffer = frameBuffer;
        #end

        resize(width, height);
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if ogl
            frameBuffer = null;
            renderTarget.frameBuffer = null;
        #end
        nativeTexture = null;
    }

    public function resize(width:Int, height:Int):Void {
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


                GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, nativeTexture, 0);

                GL.bindTexture(GL.TEXTURE_2D, null);
                GL.bindRenderbuffer(GL.RENDERBUFFER, null);
                GL.bindFramebuffer(GL.FRAMEBUFFER, null);
            #end
        }
    }

    public function readBack(data:Data):Void {
        #if ogl
            GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
            GL.readPixels(0, 0, width, height, GL.RGBA, format, data);
        #end
    }
}
