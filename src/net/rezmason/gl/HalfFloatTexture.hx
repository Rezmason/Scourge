package net.rezmason.gl;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.graphics.opengl.GL;
import lime.utils.Float32Array;
import lime.utils.UInt16Array;
import net.rezmason.utils.HalfFloatUtil;

class HalfFloatTexture extends DataTexture {
    public function new(width:Int, height:Int, bytes:Bytes, ?singleChannel:Bool):Void {
        // Float conversion init
        //*
        var input = new haxe.io.BytesInput(bytes);
        var output = new BytesOutput();
        while (input.position < input.length) output.writeFloat(HalfFloatUtil.halfFloatToFloat(input.readUInt16()));
        super(width, height, singleChannel ? LUMINANCE : RGBA, FLOAT, Float32Array.fromBytes(output.getBytes()));
        /**/
        

        // Half float init
        /*
        GL.getExtension('OES_texture_half_float');
        GL.getExtension('OES_texture_half_float_linear');

        var unpackAlignment = GL.getParameter(GL.UNPACK_ALIGNMENT);
        GL.pixelStorei(GL.UNPACK_ALIGNMENT, singleChannel ? 1 : 4);
        super(width, height, singleChannel ? LUMINANCE : RGBA, HALF_FLOAT, UInt16Array.fromBytes(bytes));
        GL.pixelStorei(GL.UNPACK_ALIGNMENT, unpackAlignment);
        /**/
    }
}
