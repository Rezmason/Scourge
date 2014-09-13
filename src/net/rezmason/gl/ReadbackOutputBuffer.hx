package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

#if flash
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
#else
    import openfl.gl.GL;
#end

class ReadbackOutputBuffer extends OutputBuffer {

    #if flash
        var bitmapData:BitmapData;
    #else
        var buf:GLOutputBuffer;
    #end

    override function init():Void {
        #if flash
            bitmapData = new BitmapData(1, 1, true, 0);
        #else
            buf = new GLOutputBuffer(GL.UNSIGNED_BYTE);
        #end
    }

    override public function resize(width:Int, height:Int):Bool {

        if (!super.resize(width, height)) return false;

        #if flash
            if (bitmapData != null) bitmapData.dispose();
            bitmapData = new BitmapData(width, height, true, 0);
        #else
            buf.resize(width, height);
        #end

        return true;
    }

    public inline function createReadbackData():ReadbackData {
        return new ReadbackData(#if !flash width * height * 4 #end);
    }

    public inline function readBack(outputBuffer:OutputBuffer, data:ReadbackData):Void {
        #if flash
            if (bitmapData != null) {
                data.position = 0;
                bitmapData.copyPixelsToByteArray(bitmapData.rect, data);
                data.position = 0;
            }
        #else
            GL.bindFramebuffer(GL.FRAMEBUFFER, buf.frameBuffer);
            GL.readPixels(0, 0, width, height, GL.RGBA, buf.format, data);
        #end
    }

    @:allow(net.rezmason.gl)
    override function activate():Void {
        #if flash
            context.setRenderToBackBuffer();
        #else
            GL.bindFramebuffer(GL.FRAMEBUFFER, buf.frameBuffer);
        #end
    }

    @:allow(net.rezmason.gl)
    override function deactivate():Void {
        #if flash
            context.drawToBitmapData(bitmapData);
        #end
    }
}
