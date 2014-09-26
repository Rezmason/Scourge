package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if !flash
    import openfl.gl.GL;
    import openfl.gl.GLFramebuffer;
    import openfl.gl.GLRenderbuffer;
#end

@:allow(net.rezmason.gl)
class BufferTexture extends Texture {

    var format:TextureFormat;
    var nativeTexture:NativeTexture;
    var width:Int;
    var height:Int;
    #if !flash
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
        #if !flash
            nativeTexture = GL.createTexture();
            frameBuffer = GL.createFramebuffer();
            renderBuffer = GL.createRenderbuffer();
        #end

        resize(width, height);
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash
            nativeTexture.dispose();
        #else
            frameBuffer = null;
            renderBuffer = null;
        #end
        
        nativeTexture = null;
    }

    @:allow(net.rezmason.gl)
    override function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {
        if (index != -1) {
            #if flash
                prog.setTextureAt(location, nativeTexture);
            #else
                GL.activeTexture(GL.TEXTURE0 + index);
                GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                GL.uniform1i(location, index);
            #end
        }
    }

    function resize(width:Int, height:Int):Void {
        if (width  < 1) width = 1;
        if (height < 1) height = 1;
        this.width = width;
        this.height = height;
        if (isConnectedToContext()) {
            #if flash
                if (nativeTexture != null) nativeTexture.dispose();
                // TODO: make this dependent on format?
                nativeTexture = context.createRectangleTexture(width, height, cast "rgbaHalfFloat", true);
            #else
                GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);

                GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

                GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, cast format, null);

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
