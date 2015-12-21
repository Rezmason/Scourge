package net.rezmason.utils.display;

import haxe.Utf8;
import haxe.io.Bytes;
import haxe.io.BytesInput;

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

class FlatFont {

    var charUVs:Map<UInt, Array<UV>>;
    
    public var data(default, null):Bytes;
    public var glyphWidth(default, null):UInt;
    public var glyphHeight(default, null):UInt;
    public var width(default, null):UInt;
    public var height(default, null):UInt;
    public var range(default, null):Float;
    public var glyphRatio(default, null):Float;

    public function new(htf:Bytes):Void {
        var input:BytesInput = new BytesInput(htf);
        width = input.readUInt16();
        height = input.readUInt16();
        glyphWidth = input.readUInt16();
        glyphHeight = input.readUInt16();
        glyphRatio = input.readFloat();
        range = input.readFloat();
        charUVs = new Map();
        for (ike in 0...input.readUInt16()) {
            var code = input.readUInt16();
            var left:Float   = input.readFloat();
            var right:Float  = input.readFloat();
            var top:Float    = input.readFloat();
            var bottom:Float = input.readFloat();
            charUVs[code] = [{u:left, v:top}, {u:right, v:top}, {u:right, v:bottom}, {u:left, v:bottom}];
        }
        data = htf.sub(input.position, htf.length - input.position);
    }

    public inline function getCharUVs(char:String):Array<UV> return getCharCodeUVs(Utf8.charCodeAt(char, 0));
    public inline function getCharCodeUVs(code:UInt):Array<UV> return charUVs[code];
}
