package net.rezmason.gl;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import lime.utils.UInt16Array;
import net.rezmason.gl.capabilities.Capabilities;
import net.rezmason.gl.capabilities.UploadHalfFloatTextureProbe;
import net.rezmason.utils.HalfFloatUtil;

class HalfFloatTexture extends DataTexture {

    static var halfFloatTextureUploading:Bool = true;

    public function new(width:Int, height:Int, bytes:Bytes, ?singleChannel:Bool):Void {

        var supported = Capabilities.isSupported(UploadHalfFloatTextureProbe);

        var dataType:DataType = supported ? HALF_FLOAT : FLOAT;
        var data:ArrayBufferView = supported ? UInt16Array.fromBytes(bytes) : halfFloatToFloat(bytes);
        super(width, height, singleChannel ? SINGLE_CHANNEL : RGBA, dataType, data);
    }

    inline function halfFloatToFloat(halfFloatBytes:Bytes):Float32Array {
        var input = new BytesInput(halfFloatBytes);
        var output = new BytesOutput();
        while (input.position < input.length) output.writeFloat(HalfFloatUtil.halfFloatToFloat(input.readUInt16()));
        return Float32Array.fromBytes(output.getBytes());
    }
}
