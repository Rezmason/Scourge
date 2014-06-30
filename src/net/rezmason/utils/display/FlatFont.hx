package net.rezmason.utils.display;

import flash.display.BitmapData;
import flash.geom.Matrix;

import haxe.Utf8;

using haxe.JSON;

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

typedef FlatFontJSON = {
    var glyphWidth:Int;
    var glyphHeight:Int;
    var glyphRatio:Float;
    var charCoords:Dynamic;
    var missingChars:Dynamic;
};

@:allow(net.rezmason.utils.display.FlatFontGenerator)
class FlatFont {

    var bitmapData:BitmapData;
    var charCoords:Map<Int, CharCoord>;
    var missingChars:Array<Int>;
    var defaultCharCoord:CharCoord;
    var jsonString:String;

    public var glyphWidth(default, null):Int;
    public var glyphHeight(default, null):Int;
    public var glyphRatio(default, null):Float;
    public var bdWidth(default, null):Int;
    public var bdHeight(default, null):Int;
    public var rowFraction(default, null):Float;
    public var columnFraction(default, null):Float;

    public function new(bitmapData:BitmapData, jsonString:String):Void {

        this.bitmapData = bitmapData;
        bdWidth = bitmapData.width;
        bdHeight = bitmapData.height;

        this.jsonString = jsonString;
        charCoords = new Map();
        missingChars = [];

        var expandedJSON:FlatFontJSON = jsonString.parse();
        glyphWidth = expandedJSON.glyphWidth;
        glyphHeight = expandedJSON.glyphHeight;
        glyphRatio = expandedJSON.glyphRatio;
        rowFraction = glyphHeight / bitmapData.height;
        columnFraction = glyphWidth / bitmapData.width;

        for (field in Reflect.fields(expandedJSON.charCoords)) {
            var code:Int = Std.parseInt(field.substr(1));
            charCoords[code] = cast Reflect.field(expandedJSON.charCoords, field);
        }

        missingChars = expandedJSON.missingChars;

        defaultCharCoord = {x:0, y:0};
    }

    public inline function getCharMatrix(char:String):Matrix {
        return getCharCodeMatrix(Utf8.charCodeAt(char, 0));
    }

    public inline function getCharCodeMatrix(code:Int):Matrix {
        var charCoord:CharCoord = charCoords[code];
        var mat:Matrix = new Matrix();
        if (charCoord != null) {
            mat.tx = -charCoord.x;
            mat.ty = -charCoord.y;
        }
        return mat;
    }

    public inline function getCharUVs(char:String, crop:Float = 0):Array<UV> {
        return getCharCodeUVs(Utf8.charCodeAt(char, 0), crop);
    }

    public inline function getCharCodeUVs(code:Int, crop:Float = 0):Array<UV> {
        var charCoord:CharCoord = charCoords[code];
        if (charCoord == null) charCoord = defaultCharCoord;

        var bumpU:Float = 0.5 / bdWidth;
        var bumpV:Float = 0.5 / bdHeight;

        var uvs:Array<UV> = [];
        var u:Float = charCoord.x / bdWidth;
        var v:Float = charCoord.y / bdHeight;

        uvs.push({u:u                  + bumpU, v:v               + bumpV});
        uvs.push({u:u + columnFraction - bumpU, v:v               + bumpV});
        uvs.push({u:u + columnFraction - bumpU, v:v + rowFraction - bumpV});
        uvs.push({u:u                  + bumpU, v:v + rowFraction - bumpV});

        if (crop != 0) {

            var cropU:Float = crop * glyphWidth / bdWidth;

            uvs[0].u += cropU;
            uvs[1].u -= cropU;
            uvs[2].u -= cropU;
            uvs[3].u += cropU;

            var cropV:Float = crop * glyphHeight / bdHeight;

            uvs[0].v += cropV;
            uvs[1].v += cropV;
            uvs[2].v -= cropV;
            uvs[3].v -= cropV;
        }

        return uvs;
    }

    public inline function getBitmapDataClone():BitmapData { return bitmapData.clone(); }

    public inline function exportJSON():String { return jsonString; }
}
