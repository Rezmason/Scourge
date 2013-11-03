package net.rezmason.utils;

import flash.display.BitmapData;
import flash.geom.Matrix;

import haxe.Utf8;

#if flash
    import flash.display.BlendMode;
    import flash.geom.Rectangle;
    import flash.text.engine.ElementFormat;
    import flash.text.engine.FontDescription;
    import flash.text.engine.TextBlock;
    import flash.text.engine.TextElement;
    import flash.text.engine.TextLine;
    import flash.text.Font;
    import flash.utils.ByteArray;

    import openfl.Assets.getBytes;
    import net.rezmason.utils.TempAgency;
#end

using haxe.JSON;

#if flash
    using Lambda;
    using net.rezmason.utils.Alphabetizer;
#end

typedef CharCoord = {x:Int, y:Int};
typedef UV = {u:Float, v:Float};

typedef FlatFontJSON = {
    var glyphWidth:Int;
    var glyphHeight:Int;
    var glyphRatio:Float;
    var charCoords:Dynamic;
    var missingChars:Dynamic;
};

#if flash
    typedef SerializedBitmap = {
        var width:Int;
        var height:Int;
        var bytes:ByteArray;
    }
#end

class FlatFont {

    var bitmapData:BitmapData;
    var charCoords:Map<Int, CharCoord>;
    var missingChars:Array<Int>;
    var defaultCharCoord:CharCoord;
    var jsonString:String;

    #if flash
        static var sdfAgency:TempAgency<{source:SerializedBitmap, cutoff:Int}, SerializedBitmap>;
    #end

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
    public static function flatten(font:Font, fontSize:Int, charString:String, glyphWidth:Int, glyphHeight:Int, spacing:Int, cutoff:Int, cbk:FlatFont->Void):Void {

        if (sdfAgency == null) sdfAgency = new TempAgency(getBytes("flash_workers/SDFWorker.swf"));

        if (fontSize < 1) fontSize = 72;
        if (glyphWidth  < 0) glyphWidth  = 1;
        if (glyphHeight < 0) glyphHeight = 1;
        if (spacing < 0) spacing = 0;

        var charCoordJSON:Dynamic = {};
        var missingChars:Array<Int> = [];
        var requiredChars:Map<String, Bool> = new Map();
        var numChars:Int = 0;

        for (char in charString.split('')) {
            if (!requiredChars.exists(char)) {
                if (font.hasGlyphs(char)) {
                    numChars++;
                    requiredChars[char] = true;
                } else {
                    missingChars.push(char.charCodeAt(0));
                }
            }
        }

        var numColumns:Int = Std.int(Math.sqrt(numChars)) + 1;
        var numRows:Int = Std.int(numChars / numColumns) + 1;

        var chars:Array<String> = [];
        for (char in requiredChars.keys().a2z()) chars.push(char);

        var glyphs:Array<TextLine> = [];
        var bds:Array<BitmapData> = [];

        var glyphBounds:Rectangle = null;
        var imageBounds:Rectangle = null;
        var sdfBounds:Rectangle = null;

        var format:ElementFormat = new ElementFormat(new FontDescription(font.fontName));
        format.fontSize = fontSize;
        format.color = 0xFFFFFF;
        var textBlock:TextBlock = new TextBlock();
        var glyphBounds:Rectangle = new Rectangle();

        for (char in chars) {
            textBlock.content = new TextElement(char, format);
            var textLine:TextLine = textBlock.createTextLine(null);
            glyphs.push(textLine);
            glyphBounds = glyphBounds.union(textLine.getBounds(textLine));
        }

        imageBounds = glyphBounds.clone();
        imageBounds.inflate(spacing * 2, spacing * 2);

        imageBounds.left   = Math.floor(imageBounds.left  );
        imageBounds.right  = Math.ceil (imageBounds.right );
        imageBounds.top    = Math.floor(imageBounds.top   );
        imageBounds.bottom = Math.ceil (imageBounds.bottom);

        sdfBounds = imageBounds.clone();
        sdfBounds.inflate(cutoff, cutoff);

        var glyphBD:BitmapData = new BitmapData(Std.int(imageBounds.width), Std.int(imageBounds.height), true, 0xFF000000);
        var glyphMat:Matrix = new Matrix();
        glyphMat.tx = -imageBounds.left;
        glyphMat.ty = -imageBounds.top;

        var numSDFs:Int = 0;

        function proceed():Void {

            var width:Int = largestPowerOfTwo(Std.int(Math.max(glyphWidth * numColumns, glyphHeight * numRows)));
            var bitmapData:BitmapData = new BitmapData(width, width, true, 0xFF0000FF);

            var x:Int = 0;
            var y:Int = 0;
            var outputMat:Matrix = new Matrix();
            outputMat.scale(glyphWidth / sdfBounds.width, glyphHeight / sdfBounds.height);

            for (ike in 0...numChars) {
                outputMat.tx = x * glyphWidth;
                outputMat.ty = y * glyphHeight;

                bitmapData.draw(bds[ike], outputMat, null, BlendMode.NORMAL, null, true);

                Reflect.setField(charCoordJSON, '_' + chars[ike].charCodeAt(0), {x: outputMat.tx, y: outputMat.ty});

                x++;
                if (x > numColumns) {
                    x = 0;
                    y++;
                }
            }

            var glyphRatio:Float = imageBounds.height / imageBounds.width;

            var json:FlatFontJSON = {
                glyphWidth:glyphWidth,
                glyphHeight:glyphHeight,
                glyphRatio:glyphRatio,
                charCoords:charCoordJSON,
                missingChars:missingChars
            };

            cbk (new FlatFont(bitmapData, json.stringify()));
        }

        function addSDF(index:Int, sdf:SerializedBitmap):Void {
            numSDFs++;

            var bd:BitmapData = new BitmapData(sdf.width, sdf.height, true, 0x0);
            bd.setPixels(bd.rect, sdf.bytes);

            bds[index] = bd;
            trace('$index: $numSDFs / $numChars');
            if (numSDFs == numChars) proceed();
        }

        for (ike in 0...numChars) {
            var bd:BitmapData = glyphBD.clone();
            bd.draw(glyphs[ike], glyphMat, null, BlendMode.NORMAL, null, true);

            var sb:SerializedBitmap = {width:bd.width, height:bd.height, bytes:bd.getPixels(bd.rect)};
            sdfAgency.addWork({source:sb, cutoff:cutoff}, addSDF.bind(ike));
        }
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
