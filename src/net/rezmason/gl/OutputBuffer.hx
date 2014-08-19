package net.rezmason.gl;

#if flash
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
#else
    import openfl.gl.GL;
    import openfl.gl.GLFramebuffer;
    import openfl.gl.GLRenderbuffer;
    import openfl.gl.GLTexture;
#end

typedef Context = #if flash flash.display3D.Context3D #else Class<openfl.gl.GL> #end ;

@:allow(net.rezmason.gl)
class OutputBuffer {

    var context:Context;

    public var texture(default, null):Texture;

    #if flash
        var bitmapData:BitmapData;
    #else
        var frameBuffer:GLFramebuffer;
        var glTexture:GLTexture;
        var renderBuffer:GLRenderbuffer;
    #end

    var type:net.rezmason.gl.OutputBufferType;

    public var width(default, null):Int;
    public var height(default, null):Int;

    @:allow(net.rezmason.gl)
    function new(type:OutputBufferType, context:Context):Void {
        this.type = type;
        this.context = context;

        #if flash
            switch (type) {
                case VIEWPORT:
                case READBACK: bitmapData = new BitmapData(1, 1, true, 0);
                case TEXTURE: texture = TEX(context.createRectangleTexture(1, 1, Context3DTextureFormat.BGRA, true));
            }
        #else
            switch (type) {
                case VIEWPORT:
                case _:
                    frameBuffer = GL.createFramebuffer();
                    glTexture = GL.createTexture();
                    renderBuffer = GL.createRenderbuffer();
                    texture = TEX(glTexture);
            }
        #end
    }

    public function resize(width:Int, height:Int):Void {

        if (this.width == width && this.height == height) return;

        this.width = width;
        this.height = height;

        #if flash
            switch (type) {
                case VIEWPORT: context.configureBackBuffer(width, height, 2, true);
                case READBACK:
                    if (bitmapData != null) bitmapData.dispose();
                    bitmapData = new BitmapData(width, height, true, 0);
                case TEXTURE:
                    texture = TEX(context.createRectangleTexture(width, height, Context3DTextureFormat.BGRA, true));
            }
        #else
            switch (type) {
                case VIEWPORT: GL.viewport(0, 0, width, height);
                case _:
                    GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);

                    GL.bindTexture(GL.TEXTURE_2D, glTexture);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

                    GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

                    GL.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
                    GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);

                    GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, glTexture, 0);
                    GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

                    GL.bindTexture(GL.TEXTURE_2D, null);
                    GL.bindRenderbuffer(GL.RENDERBUFFER, null);
                    GL.bindFramebuffer(GL.FRAMEBUFFER, null);
            }
        #end
    }
}
