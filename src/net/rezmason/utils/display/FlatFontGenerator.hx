package net.rezmason.utils.display;

import flash.display.BitmapData;
import flash.geom.Matrix;

import haxe.Utf8;
import haxe.io.Bytes;

import flash.display.BlendMode;
import flash.geom.Rectangle;
import flash.text.engine.ElementFormat;
import flash.text.engine.FontDescription;
import flash.text.engine.TextBlock;
import flash.text.engine.TextElement;
import flash.text.engine.TextLine;
import flash.text.Font;
import flash.utils.ByteArray;

import net.rezmason.utils.display.FlatFont;
import net.rezmason.utils.display.SDFTypes;
import net.rezmason.utils.workers.TempAgency;
import net.rezmason.utils.workers.Golem;

using haxe.JSON;

using Lambda;
using net.rezmason.utils.Alphabetizer;

typedef CharacterSet = {
    var font:Font;
    var chars:String;
    var size:Float;
}

class FlatFontGenerator {

    static var sdfAgency:TempAgency<{source:SerializedBitmap, cutoff:Int}, SerializedBitmap>;

    public static function flatten(sets:Array<CharacterSet>, glyphWidth:UInt, glyphHeight:UInt, spacing:UInt, cutoff:Int, cbk:FlatFont->Void):Void {

        if (sdfAgency == null) {
            sdfAgency = new TempAgency(Golem.rise('SDFWorker.hxml'), 10);
            sdfAgency.onDone = sdfAgency.die;
            sdfAgency.onError = function(_) trace(_);
        }

        if (glyphWidth  == 0) glyphWidth  = 1;
        if (glyphHeight == 0) glyphHeight = 1;
        
        var charCoordJSON:Dynamic = {};
        var missingChars:Array<Int> = [];
        var requiredChars:Map<String, Null<Int>> = new Map();
        var numChars:Int = 0;

        for (ike in 0...sets.length) {
            for (char in sets[ike].chars.split('')) {
                if (!requiredChars.exists(char)) {
                    numChars++;
                    requiredChars[char] = null;
                }

                if (requiredChars[char] == null && sets[ike].font.hasGlyphs(char)) {
                    requiredChars[char] = ike;
                }
            }
        }

        var numColumns:Int = Std.int(Math.sqrt(numChars)) + 1;
        var numRows:Int = Std.int(numChars / numColumns) + 1;

        var chars:Array<String> = [];
        for (char in requiredChars.keys().a2z()) {
            chars.push(char);
            if (requiredChars[char] == null) missingChars.push(char.charCodeAt(0));
        }

        var glyphs:Array<TextLine> = [];
        var bds:Array<BitmapData> = [];

        var glyphBounds:Rectangle = null;
        var imageBounds:Rectangle = null;
        var sdfBounds:Rectangle = null;

        var formats:Array<ElementFormat> = [];
        for (ike in 0...sets.length) {
            var format:ElementFormat = new ElementFormat(new FontDescription(sets[ike].font.fontName));
            format.fontSize = sets[ike].size;
            format.color = 0xFFFFFF;
            formats.push(format);
        }
        var textBlock:TextBlock = new TextBlock();
        var glyphBounds:Rectangle = null;

        for (char in chars) {
            textBlock.content = new TextElement(char, formats[requiredChars[char]]);
            var textLine:TextLine = textBlock.createTextLine(null);
            glyphs.push(textLine);
            var bounds:Rectangle = textLine.getBounds(textLine);
            if (glyphBounds == null) glyphBounds = bounds;
            else glyphBounds = glyphBounds.union(bounds);
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

            var width :Int = Std.int(Math.ceil(glyphWidth  * numColumns));
            var height:Int = Std.int(Math.ceil(glyphHeight * numRows   ));
            
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
                if (x >= numColumns) {
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

            var ba = sdf.bytes.getData();
            ba.endian = flash.utils.Endian.BIG_ENDIAN;
            ba.position = 0;
            
            var bd:BitmapData = new BitmapData(sdf.width, sdf.height, true, 0x0);
            bd.setPixels(bd.rect, ba);

            bds[index] = bd;
            trace('$index: $numSDFs / $numChars');
            if (numSDFs == numChars) proceed();
        }

        for (ike in 0...numChars) {
            var bd:BitmapData = glyphBD.clone();
            bd.draw(glyphs[ike], glyphMat, null, BlendMode.NORMAL, null, true);
            var sb:SerializedBitmap = {width:bd.width, height:bd.height, bytes:Bytes.ofData(bd.getPixels(bd.rect))};
            // addSDF(ike, SDF.process({source:sb, cutoff:cutoff}));
            sdfAgency.addWork({source:sb, cutoff:cutoff}, addSDF.bind(ike));
        }
    }
}
