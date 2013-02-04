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

using Lambda;
using haxe.JSON;
using net.rezmason.utils.Alphabetizer;

typedef CharCoord = {x:Int, y:Int};

typedef FlatFontJSON = {
    var charWidth:Int;
    var charHeight:Int;
    var charCoords:Dynamic;
};

class FlatFont {

    var bitmapData:BitmapData;
    public var charWidth(default, null):Int;
    public var charHeight(default, null):Int;
    var charCoords:Hash<CharCoord>;
    var jsonString:String;

    public function new(bitmapData:BitmapData, jsonString:String):Void {
        this.bitmapData = bitmapData;
        this.jsonString = jsonString;
        charCoords = new Hash<CharCoord>();

        var expandedJSON:FlatFontJSON = jsonString.parse();
        charWidth = expandedJSON.charWidth;
        charHeight = expandedJSON.charHeight;
        for (field in Reflect.fields(expandedJSON.charCoords)) {
            charCoords.set(field, Reflect.field(expandedJSON.charCoords, field));
        }
    }

    public inline function getCharMatrix(char:String):Matrix {
        var mat:Matrix = new Matrix();
        var charCoord:CharCoord = charCoords.get(char);
        if (charCoord != null) {
            mat.tx = -charCoord.x;
            mat.ty = -charCoord.y;
        }
        return mat;
    }

    public inline function getBitmapDataClone():BitmapData { return bitmapData.clone(); }

    public inline function exportJSON():String { return jsonString; }

    public static function flatten(font:Font, charString:String, charWidth:Int, charHeight:Int, spacing:Int):FlatFont {

        if (charWidth  < 0) charWidth  = 1;
        if (charHeight < 0) charHeight = 1;

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
        var bitmapData:BitmapData = new BitmapData(
            charXOffset * numColumns - spacing,
            charYOffset * numRows    - spacing,
            true, 0x01FFFFFF
        );
        //bitmapData.fillRect(bitmapData.rect, 0xFFFFFFFF);

        var sp:Sprite = new Sprite();
        var format = new TextFormat(font.fontName, 14, 0xFFFFFF);
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

            var dx:Int = x * charXOffset;
            var dy:Int = y * charYOffset;

            clipRect.x = dx;
            clipRect.y = dy;

            //if ((x + y) % 2 == 1) bitmapData.fillRect(clipRect, 0xFFFF0000);

            textField.text = char;
            mat.tx += dx;
            mat.ty += dy;

            bitmapData.draw(sp, mat, null, BlendMode.NORMAL, clipRect, true);

            Reflect.setField(charCoordJSON, char, {x: dx, y: dy});

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
}
