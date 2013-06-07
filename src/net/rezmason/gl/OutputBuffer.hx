package net.rezmason.gl;

#if flash
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
#else
    import openfl.gl.GL;
    import openfl.gl.GLFramebuffer;
    import openfl.gl.GLRenderbuffer;
    import openfl.gl.GLTexture;
#end

class OutputBuffer {

    #if flash
        @:allow(net.rezmason.gl) var bitmapData:BitmapData;
        var context:Context3D;
    #else
        @:allow(net.rezmason.gl) var frameBuffer:GLFramebuffer;
        var texture:GLTexture;
        var renderBuffer:GLRenderbuffer;
    #end

    var empty:Bool;

    public function new(?empty:Bool #if flash, ?context:Context3D #end):Void {
        this.empty = empty;

        #if flash
            this.context = context;
        #end

        if (!empty) {
            #if flash
                bitmapData = new BitmapData(1, 1, true, 0);
            #else
                frameBuffer = GL.createFramebuffer();
                texture = GL.createTexture();
                renderBuffer = GL.createRenderbuffer();
            #end
        }
    }

    public function resize(width:Int, height:Int):Void {
        if (empty) {
            #if flash
                context.configureBackBuffer(width, height, 2, true);
            #else
                GL.viewport(0, 0, width, height);
            #end
        } else {
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
        }
    }
}
