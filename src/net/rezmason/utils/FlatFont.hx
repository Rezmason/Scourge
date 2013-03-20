package net.rezmason.utils;

import nme.display.BitmapData;
import nme.display.BlendMode;
import nme.display.Sprite;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.text.AntiAliasType;
import nme.text.Font;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;
import nme.text.TextFormat;

import haxe.Utf8;

using Lambda;
using haxe.JSON;
using net.rezmason.utils.Alphabetizer;

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

typedef FlatFontJSON = {
    var charWidth:Int;
    var charHeight:Int;
    var charCoords:Dynamic;
};

class FlatFont {

    var bitmapData:BitmapData;
    var charCoords:IntHash<CharCoord>;
    var defaultCharCoord:CharCoord;
    var jsonString:String;

    public var charWidth(default, null):Int;
    public var charHeight(default, null):Int;
    public var bdWidth(default, null):Int;
    public var bdHeight(default, null):Int;
    public var rowFraction(default, null):Float;
    public var columnFraction(default, null):Float;

    public function new(bitmapData:BitmapData, jsonString:String):Void {
        this.bitmapData = bitmapData;
        bdWidth = bitmapData.width;
        bdHeight = bitmapData.height;

        this.jsonString = jsonString;
        charCoords = new IntHash<CharCoord>();

        var expandedJSON:FlatFontJSON = jsonString.parse();
        charWidth = expandedJSON.charWidth;
        charHeight = expandedJSON.charHeight;
        rowFraction = charHeight / bitmapData.height;
        columnFraction = charWidth / bitmapData.width;

        for (field in Reflect.fields(expandedJSON.charCoords)) {
            var code:Int = Std.parseInt(field.substr(1));
            charCoords.set(code, Reflect.field(expandedJSON.charCoords, field));
        }

        defaultCharCoord = {x:0, y:0};
    }

    public inline function getCharMatrix(char:String):Matrix {
        return getCharCodeMatrix(Utf8.charCodeAt(char, 0));
    }

    public inline function getCharCodeMatrix(code:Int):Matrix {
        var charCoord:CharCoord = charCoords.get(code);
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
        var charCoord:CharCoord = charCoords.get(code);
        if (charCoord == null) charCoord = defaultCharCoord;

        var uvs:Array<UV> = [];
        var u:Float = charCoord.x / bdWidth;
        var v:Float = charCoord.y / bdHeight;

        uvs.push({u:u                 , v:v              });
        uvs.push({u:u + columnFraction, v:v              });
        uvs.push({u:u + columnFraction, v:v + rowFraction});
        uvs.push({u:u                 , v:v + rowFraction});

        return uvs;
    }

    public inline function getBitmapDataClone():BitmapData { return bitmapData.clone(); }

    public inline function exportJSON():String { return jsonString; }

    #if flash
    public static function flatten(font:Font, fontSize:Int, charString:String, charWidth:Int, charHeight:Int, spacing:Int):FlatFont {

        if (fontSize < 1) fontSize = 72;
        if (charWidth  < 0) charWidth  = 1;
        if (charHeight < 0) charHeight = 1;
        if (spacing < 0) spacing = 0;

        var charXOffset:Int = charWidth  + spacing;
        var charYOffset:Int = charHeight + spacing;

        var charCoordJSON:Dynamic = {};
        var requiredChars:Hash<Bool> = new Hash<Bool>();
        var numChars:Int = 1;

        for (char in charString.split("")) {
            if (!~/\s+/g.match(char) && !requiredChars.exists(char)) {
                numChars++;
                requiredChars.set(char, true);
            }
        }

        var numColumns:Int = Std.int(Math.sqrt(numChars)) + 1;
        var numRows:Int = Std.int(numChars / numColumns) + 1;

        var width:Int = Std.int(Math.max(charXOffset * numColumns, charYOffset * numRows)) + spacing;
        var bitmapData:BitmapData = new BitmapData(width, width, false, 0);
        //bitmapData.fillRect(bitmapData.rect, 0xFFFFFFFF);

        var sp:Sprite = new Sprite();
        var format = new TextFormat(font.fontName, fontSize, 0xFFFFFF);
        var textField = new TextField();
        sp.addChild(textField);
        textField.antiAliasType = AntiAliasType.ADVANCED;
        #if flash textField.thickness = 100; #end
        //textField.sharpness = -400;
        textField.defaultTextFormat = format;
        textField.selectable = false;
        textField.embedFonts = true;
        textField.width = 5;
        textField.height = 5;
        textField.x = 0;
        textField.y = 0;
        textField.autoSize = TextFieldAutoSize.LEFT;

        textField.text = " ";
        var charBounds = textField.getCharBoundaries(0);

        var x:Int = 1;
        var y:Int = 0;
        var mat = new Matrix();
        mat.translate(-charBounds.x, -charBounds.y);
        mat.scale(charWidth / charBounds.width, charHeight / charBounds.height);

        var clipRect:Rectangle = new Rectangle(0, 0, charWidth, charHeight);

        for (char in requiredChars.keys().a2z()) {

            var dx:Int = x * charXOffset + spacing;
            var dy:Int = y * charYOffset + spacing;

            clipRect.x = dx;
            clipRect.y = dy;

            //if ((x + y) % 2 == 1) bitmapData.fillRect(clipRect, 0xFFFF0000);

            textField.text = char;
            mat.tx += dx;
            mat.ty += dy;

            bitmapData.draw(sp, mat, null, BlendMode.NORMAL, clipRect, true);

            Reflect.setField(charCoordJSON, "_" + char.charCodeAt(0), {x: dx, y: dy});

            mat.tx -= dx;
            mat.ty -= dy;

            x++;
            if (x >= numColumns) {
                x = 0;
                y++;
            }
        }

        var json:FlatFontJSON = {charWidth:charWidth, charHeight:charHeight, charCoords:charCoordJSON};

        return new FlatFont(bitmapData, json.stringify());
    }
    #end
}
