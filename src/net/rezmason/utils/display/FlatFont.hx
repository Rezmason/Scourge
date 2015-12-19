package net.rezmason.utils.display;

import haxe.Utf8;
import haxe.io.Bytes;
import haxe.io.BytesInput;

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

class FlatFont {

    var data:Array<Float>;
    var charCoords:Map<UInt, CharCoord>;
    var defaultCharCoord:CharCoord;
    var charUVs:Map<UInt, Array<UV>>;

    public var glyphWidth(default, null):UInt;
    public var glyphHeight(default, null):UInt;
    public var width(default, null):UInt;
    public var height(default, null):UInt;
    public var range(default, null):Float;
    public var glyphRatio(default, null):Float;
    public var rowFraction(default, null):Float;
    public var columnFraction(default, null):Float;

    public function new(htf:Bytes):Void {
        var input = new BytesInput(htf);
        width = input.readUInt16();
        height = input.readUInt16();
        glyphWidth = input.readUInt16();
        glyphHeight = input.readUInt16();
        glyphRatio = input.readFloat();
        range = input.readFloat();
        charCoords = new Map();
        for (ike in 0...input.readUInt16()) charCoords[input.readUInt16()] = {x:input.readUInt16(), y:input.readUInt16()};
        rowFraction = glyphHeight / height;
        columnFraction = glyphWidth / width;
        data = [for (ike in 0...width * height * 4) (ike % 4 == 2) ? input.readFloat() : 1];
        charUVs = new Map();
        defaultCharCoord = {x:0, y:0};
    }

    public inline function getCharUVs(char:String):Array<UV> {
        return getCharCodeUVs(Utf8.charCodeAt(char, 0));
    }

    public inline function getCharCodeUVs(code:Int):Array<UV> {
        var uvs:Array<UV> = charUVs[code];
        if (uvs == null) {
            uvs = [];
            var charCoord:CharCoord = charCoords[code];
            if (charCoord == null) charCoord = defaultCharCoord;

            var bumpU:Float = 0.5 / width;
            var bumpV:Float = 0.5 / height;

            var u:Float = charCoord.x / width;
            var v:Float = charCoord.y / height;

            uvs.push({u:u                  + bumpU, v:v               + bumpV});
            uvs.push({u:u + columnFraction - bumpU, v:v               + bumpV});
            uvs.push({u:u + columnFraction - bumpU, v:v + rowFraction - bumpV});
            uvs.push({u:u                  + bumpU, v:v + rowFraction - bumpV});
            charUVs[code] = uvs;
        }
        return uvs;
    }

    public inline function getData() return data.copy();
}
