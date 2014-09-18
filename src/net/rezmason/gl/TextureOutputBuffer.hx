package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

#if flash
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
#else
    import openfl.gl.GL;
#end

class TextureOutputBuffer extends OutputBuffer {

    var tex:NativeTexture;

    #if !flash
        var buf:GLOutputBuffer;
    #end

    override function init():Void {
        #if flash
            tex = context.createRectangleTexture(1, 1, cast "rgbaHalfFloat", true); // Context3DTextureFormat.RGBA_HALF_FLOAT
        #else
            buf = new GLOutputBuffer(GL.FLOAT);
            tex = buf.texture;
        #end
    }

    override public function resize(width:Int, height:Int):Bool {

        if (!super.resize(width, height)) return false;

        #if flash
            if (tex != null) tex.dispose();
            tex = context.createRectangleTexture(width, height, cast "rgbaHalfFloat", true); // Context3DTextureFormat.RGBA_HALF_FLOAT
        #else
            buf.resize(width, height);
        #end

        return true;
    }

    public inline function getTexture():Texture return TEX(tex);

    @:allow(net.rezmason.gl)
    override function activate():Void {
        #if flash
            context.setRenderToTexture(tex);
        #else
            GL.bindFramebuffer(GL.FRAMEBUFFER, buf.frameBuffer);
        #end
    }
}
