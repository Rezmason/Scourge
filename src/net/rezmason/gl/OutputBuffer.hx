package net.rezmason.gl;

#if flash
    import flash.display.BitmapData;
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

    #if flash
        var bitmapData:BitmapData;
    #else
        var frameBuffer:GLFramebuffer;
        var texture:GLTexture;
        var renderBuffer:GLRenderbuffer;
    #end

    var type:net.rezmason.gl.OutputBufferType;

    public var width(default, null):Int;
    public var height(default, null):Int;

    @:allow(net.rezmason.gl)
    function new(type:OutputBufferType, context:Context):Void {
        this.type = type;

        this.context = context;

        switch (type) {
            case VIEWPORT:
            case READBACK:
                #if flash
                    bitmapData = new BitmapData(1, 1, true, 0);
                #else
                    frameBuffer = GL.createFramebuffer();
                    texture = GL.createTexture();
                    renderBuffer = GL.createRenderbuffer();
                #end
            case TEXTURE:
        }
    }

    public function resize(width:Int, height:Int):Void {

        if (this.width == width && this.height == height) return;

        this.width = width;
        this.height = height;

        switch (type) {
            case VIEWPORT:
                #if flash
                    context.configureBackBuffer(width, height, 2, true);
                #else
                    GL.viewport(0, 0, width, height);
                #end
            case READBACK:
                #if flash
                    if (bitmapData != null) bitmapData.dispose();
                    bitmapData = new BitmapData(width, height, true, 0);
                #else
                    GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);

                    GL.bindTexture(GL.TEXTURE_2D, texture);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);

                    GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

                    GL.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
                    GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);

                    GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
                    GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

                    GL.bindTexture(GL.TEXTURE_2D, null);
                    GL.bindRenderbuffer(GL.RENDERBUFFER, null);
                    GL.bindFramebuffer(GL.FRAMEBUFFER, null);
                #end
            case TEXTURE:
        }
    }
}
