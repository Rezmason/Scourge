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

    public var texture(default, null):BufferTexture;

    override function init():Void {
        texture = new BufferTexture(context, FLOAT);
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
