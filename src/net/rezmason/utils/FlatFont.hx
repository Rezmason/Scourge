package net.rezmason.utils;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import haxe.Utf8;

using Lambda;
using haxe.JSON;
using net.rezmason.utils.Alphabetizer;

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

typedef FlatFontJSON = {
    var glyphWidth:Int;
    var glyphHeight:Int;
    var glyphRatio:Float;
    var charCoords:Dynamic;
    var missingChars:Dynamic;
};

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

    public inline function getCharUVs(char:String):Array<UV> {
        return getCharCodeUVs(Utf8.charCodeAt(char, 0));
    }

    public inline function getCharCodeUVs(code:Int):Array<UV> {
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

        return uvs;
    }

    public inline function getBitmapDataClone():BitmapData { return bitmapData.clone(); }

    public inline function exportJSON():String { return jsonString; }

    inline static function largestPowerOfTwo(input:Int):Int {
        var output:Int = 1;
        while (output < input) output = output * 2;
        return output;
    }

    #if flash
    public static function flatten(font:Font, fontSize:Int, charString:String, glyphWidth:Int, glyphHeight:Int, spacing:Int):FlatFont {

        if (fontSize < 1) fontSize = 72;
        if (glyphWidth  < 0) glyphWidth  = 1;
        if (glyphHeight < 0) glyphHeight = 1;
        if (spacing < 0) spacing = 0;

        var charXOffset:Int = glyphWidth  + spacing;
        var charYOffset:Int = glyphHeight + spacing;

        var charCoordJSON:Dynamic = {};
        var missingChars:Array<Int> = [];
        var requiredChars:Map<String, Bool> = new Map();
        var numChars:Int = 1;

        for (char in charString.split('')) {
            if (!~/\s+/g.match(char) && !requiredChars.exists(char)) {
                numChars++;
                requiredChars[char] = true;
            }
        }

        var numColumns:Int = Std.int(Math.sqrt(numChars)) + 1;
        var numRows:Int = Std.int(numChars / numColumns) + 1;

        var width:Int = largestPowerOfTwo(Std.int(Math.max(charXOffset * numColumns, charYOffset * numRows)) + spacing);
        var bitmapData:BitmapData = new BitmapData(width, width, true, 0xFF000000);
        //bitmapData.fillRect(bitmapData.rect, 0xFFFFFFFF);

        var sp:Sprite = new Sprite();
        var format = new TextFormat(font.fontName, fontSize, 0xFFFFFF);
        var textField = new TextField();
        sp.addChild(textField);
        textField.antiAliasType = AntiAliasType.ADVANCED;
        textField.thickness = 100;
        textField.defaultTextFormat = format;
        textField.selectable = false;
        textField.embedFonts = true;
        textField.width = 5;
        textField.height = 5;
        textField.x = 0;
        textField.y = 0;
        textField.autoSize = TextFieldAutoSize.LEFT;

        textField.text = ' ';
        var charBounds = textField.getCharBoundaries(0);
        var glyphRatio:Float = charBounds.height / charBounds.width;

        var x:Int = 1;
        var y:Int = 0;
        var mat = new Matrix();
        mat.translate(-charBounds.x, -charBounds.y);
        mat.scale(glyphWidth / charBounds.width, glyphHeight / charBounds.height);

        var clipRect:Rectangle = new Rectangle(0, 0, glyphWidth, glyphHeight);

        for (char in requiredChars.keys().a2z()) {

            var dx:Int = x * charXOffset + spacing;
            var dy:Int = y * charYOffset + spacing;
            var charCode:Int = char.charCodeAt(0);

            clipRect.x = dx;
            clipRect.y = dy;

            //if ((x + y) % 2 == 1) bitmapData.fillRect(clipRect, 0xFFFF0000);

            textField.text = char;

            if (textField.getCharBoundaries(0) == null) missingChars.push(charCode);

            mat.tx += dx;
            mat.ty += dy;

            bitmapData.draw(sp, mat, null, BlendMode.NORMAL, clipRect, true);

            Reflect.setField(charCoordJSON, '_' + charCode, {x: dx, y: dy});

            mat.tx -= dx;
            mat.ty -= dy;

            x++;
            if (x >= numColumns) {
                x = 0;
                y++;
            }
        }

        var json:FlatFontJSON = {
            glyphWidth:glyphWidth,
            glyphHeight:glyphHeight,
            glyphRatio:glyphRatio,
            charCoords:charCoordJSON,
            missingChars:missingChars
        };

        return new FlatFont(bitmapData, json.stringify());
    }
    #end

    #if flash
    public static function combine(flatFont:FlatFont, otherFlatFonts:Array<FlatFont>):FlatFont {

        var otherBDs:Array<BitmapData> = [];
        for (otherFlatFont in otherFlatFonts) otherBDs.push(otherFlatFont.getBitmapDataClone());

        var copyMat:Matrix = new Matrix();
        var clipRect:Rectangle = new Rectangle(0, 0, flatFont.glyphWidth, flatFont.glyphHeight);
        var bitmapData:BitmapData = flatFont.getBitmapDataClone();
        var missingChars:Array<Int> = [];

        for (char in flatFont.missingChars) {
            var stillMissing:Bool = true;
            for (ike in 0...otherFlatFonts.length) {
                var otherFlatFont:FlatFont = otherFlatFonts[ike];

                if (!otherFlatFont.missingChars.has(char)) {

                    var dstMat:Matrix = flatFont.getCharCodeMatrix(char);
                    var srcMat:Matrix = otherFlatFont.getCharCodeMatrix(char);
                    var otherBD:BitmapData = otherBDs[ike];

                    // Copy the character from the other font bitmap to the cloned font bitmap
                    copyMat.identity();
                    copyMat.concat(srcMat);
                    copyMat.invert();
                    copyMat.concat(dstMat);

                    clipRect.x = -dstMat.tx;
                    clipRect.y = -dstMat.ty;
                    bitmapData.draw(otherBD, copyMat, null, BlendMode.NORMAL, clipRect, true);

                    stillMissing = false;
                    break;
                }
            }

            if (stillMissing) missingChars.push(char);
        }

        var json:FlatFontJSON = {
            glyphWidth:flatFont.glyphWidth,
            glyphHeight:flatFont.glyphHeight,
            glyphRatio:flatFont.glyphRatio,
            charCoords:flatFont.jsonString.parse().charCoords,
            missingChars:missingChars
        };

        return new FlatFont(bitmapData, json.stringify());
    }
    #end
}
