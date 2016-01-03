package net.rezmason.gl;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.utils.Float32Array;

import net.rezmason.utils.HalfFloatUtil;

class HalfFloatTexture extends DataTexture {
    public function new(width:Int, height:Int, bytes:Bytes, ?singleChannel:Bool):Void {
        var input = new haxe.io.BytesInput(bytes);
        var output = new BytesOutput();
        for (ike in 0...width * height * 4) {
            var halfFloat:UInt = (!singleChannel || ike % 4 == 0) ? input.readUInt16() : 0;
            output.writeFloat(HalfFloatUtil.halfFloatToFloat(halfFloat));
        }
        super(width, height, FLOAT, Float32Array.fromBytes(output.getBytes()));
    }
}
