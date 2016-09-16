package net.rezmason.gl;

import haxe.io.Bytes;
import lime.utils.UInt16Array;

class HalfFloatTexture extends DataTexture {
    public function new(width:Int, height:Int, bytes:Bytes, ?singleChannel:Bool):Void {
        super(width, height, singleChannel ? SINGLE_CHANNEL : RGBA, HALF_FLOAT, UInt16Array.fromBytes(bytes));
    }
}
