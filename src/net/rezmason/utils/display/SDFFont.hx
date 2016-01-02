package net.rezmason.utils.display;

import haxe.Utf8;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import net.rezmason.gl.GLTypes;

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

class SDFFont {

    var charCenterUVs:Map<UInt, UV>;
    
    public var textureData(default, null):Bytes;
    public var glyphWidth(default, null):UInt;
    public var glyphHeight(default, null):UInt;
    public var width(default, null):UInt;
    public var height(default, null):UInt;
    public var sdfRange(default, null):Float;
    public var sdfCoreWidth(default, null):Float;
    public var sdfCoreHeight(default, null):Float;
    public var glyphRatio(default, null):Float;

    public var glyphData(default, null):Array<Float>;
    public var sdfData(default, null):Array<Float>;

    public function new(htf:Bytes):Void {
        var input:BytesInput = new BytesInput(htf);
        width = input.readUInt16();
        height = input.readUInt16();
        glyphWidth = input.readUInt16();
        glyphHeight = input.readUInt16();
        sdfCoreWidth = input.readUInt16();
        sdfCoreHeight = input.readUInt16();
        glyphRatio = sdfCoreHeight / sdfCoreWidth;
        sdfRange = input.readFloat();
        charCenterUVs = new Map();
        for (ike in 0...input.readUInt16()) charCenterUVs[input.readUInt16()] = {u:input.readFloat(), v:input.readFloat()};
        textureData = htf.sub(input.position, htf.length - input.position);
        glyphData = [width, height, glyphWidth, glyphHeight];
        var sdfWidthScale  = sdfCoreWidth  / (sdfCoreWidth  + 2 * sdfRange);
        var sdfHeightScale = sdfCoreHeight / (sdfCoreHeight + 2 * sdfRange);
        sdfData = [sdfWidthScale, sdfHeightScale, sdfRange, glyphRatio];
    }

    public inline function getCharCenterUV(char:String):UV return getCharCodeCenterUV(Utf8.charCodeAt(char, 0));
    public inline function getCharCodeCenterUV(code:UInt):UV return charCenterUVs[code];
}
