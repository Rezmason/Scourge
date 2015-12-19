package net.rezmason.utils.display;

import haxe.Utf8;
import haxe.io.BytesOutput;
import lime.Assets;
import lime.graphics.Image;
import lime.math.Rectangle;
import net.rezmason.math.FelzenszwalbSDF;

using net.rezmason.utils.Alphabetizer;

typedef PendingGlyph = {
    var char:String;
    var fontID:String;
    var glyph:Int;
    var image:Image;
    var width:Int;
    var height:Int;
    var offsetX:Int;
    var offsetY:Int;
};

typedef CharacterSet = {
    var fontID:String;
    var chars:String;
    var size:Int;
    var size2:Int;
}

class FlatFontGenerator {

    public static function flatten(characterSets:Array<CharacterSet>, glyphWidth, glyphHeight, spacing, range, cutoff, cbk) {

        var computedGlyphs:Map<String, Array<Float>> = new Map();
        var numChars = 0;
        var includeSpace = false;
        var glyphRatio:Float = 1;

        for (ike in 0...characterSets.length) {
            var characterSet = characterSets[ike];
            var fontID = characterSet.fontID;
            var chars = characterSet.chars;
            var fontSize = characterSet.size;
            var fontSize2 = characterSet.size2;
            var maxWidth = 0;
            var maxHeight = 0;
            var font = Assets.getFont(fontID);
            var pendingGlyphs:Map<String, PendingGlyph> = new Map();

            for (jen in 0...Utf8.length(chars)) {
                var char = Utf8.sub(chars, jen, 1);
                if (computedGlyphs.exists(char)) continue;
                if (char == ' ') {
                    if (!includeSpace) {
                        includeSpace = true;
                        numChars++;
                    }
                    continue;
                }
                
                var glyph = font.getGlyph(char);
                if (glyph == 0) continue;
                var renderedGlyph = font.renderGlyph(glyph, fontSize);
                if (renderedGlyph == null) continue;
                
                // Based on explanation at http://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html

                var renderedGlyphWidth = renderedGlyph.width;
                var renderedGlyphHeight = renderedGlyph.height;
                var metrics = font.getGlyphMetrics(glyph);
                var unit = renderedGlyphHeight / metrics.height;
                var offsetX = Std.int(metrics.horizontalBearing.x * unit);
                var offsetY = Std.int(fontSize2 - metrics.horizontalBearing.y * unit);
                var properWidth = Std.int(metrics.advance.x * unit);
                var properHeight = Std.int(metrics.advance.y * unit);
                if (properWidth  < offsetX + renderedGlyphWidth ) properWidth  = offsetX + renderedGlyphWidth;
                if (properHeight < offsetY + renderedGlyphHeight) properHeight = offsetY + renderedGlyphHeight;

                pendingGlyphs[char] = {
                    char:char,
                    fontID:fontID,
                    glyph:glyph,
                    image:renderedGlyph,
                    width:properWidth,
                    height:properHeight,
                    offsetX:offsetX,
                    offsetY:offsetY
                };
                
                if (maxWidth  < properWidth)  maxWidth  = properWidth;
                if (maxHeight < properHeight) maxHeight = properHeight;
            }

            maxWidth += 2 * range;
            maxHeight += 2 * range;

            if (ike == 0) glyphRatio = maxHeight / maxWidth;

            for (char in pendingGlyphs.keys().a2z()) {
                var pendingGlyph = pendingGlyphs[char];
                var data = pendingGlyph.image.data;
                var sdfInput = [for (ike in 0...maxWidth * maxHeight) 0.];
                for (y in 0...pendingGlyph.image.height) {
                    for (x in 0...pendingGlyph.image.width) {
                        var val:UInt = data[(y * pendingGlyph.image.width + x) * 1];
                        var outputX = x + pendingGlyph.offsetX + range;
                        var outputY = y + pendingGlyph.offsetY + range;
                        sdfInput[outputY * maxWidth + outputX] = val == 0 ? 0 : 1;
                    }
                }

                var sdfOutput = FelzenszwalbSDF.computeSignedDistanceField(maxWidth, maxHeight, sdfInput);
                sdfOutput = resize(maxWidth, maxHeight, sdfOutput, glyphWidth, glyphHeight);
                
                numChars++;
                computedGlyphs[char] = sdfOutput;
                trace(char);
            }
        }

        if (includeSpace) computedGlyphs[' '] = [for (ike in 0...glyphWidth * glyphHeight) cast range];
        var numColumns:Int = Std.int(Math.sqrt(numChars)) + 1;
        var numRows:Int = Std.int(numChars / numColumns) + 1;
        var tableWidth  = numColumns * (glyphWidth  + spacing) - spacing;
        var tableHeight = numRows    * (glyphHeight + spacing) - spacing;
        var table = [for (ike in 0...tableWidth * tableHeight) Math.POSITIVE_INFINITY];
        var row = 0;
        var col = 0;
        
        var output:BytesOutput = new BytesOutput();
        output.writeUInt16(tableWidth);
        output.writeUInt16(tableHeight);
        output.writeUInt16(glyphWidth);
        output.writeUInt16(glyphHeight);
        output.writeFloat(glyphRatio);
        output.writeFloat(range);
        output.writeUInt16(numChars);
        for (char in computedGlyphs.keys().a2z()) {
            var computedGlyph = computedGlyphs[char];
            var xOffset = col * (glyphWidth  + spacing);
            var yOffset = row * (glyphHeight + spacing);
            
            for (x in 0...glyphWidth) {
                for (y in 0...glyphHeight) {
                    table[(y + yOffset) * tableWidth + (x + xOffset)] = computedGlyph[y * glyphWidth + x];
                }
            }

            output.writeUInt16(Utf8.charCodeAt(char, 0));
            output.writeUInt16(xOffset);
            output.writeUInt16(yOffset);
            
            col++;
            if (col >= numColumns) {
                col = 0;
                row++;
            }
        }
        for (float in table) output.writeFloat(float);

        var image = makeGlyphImage(tableWidth, tableHeight, table);

        cbk(output.getBytes(), image);
    }

    static function resize(srcWidth:UInt, srcHeight:UInt, src:Array<Float>, dstWidth:UInt, dstHeight:UInt):Array<Float> {
        var dst = [];
        for (y in 0...dstHeight) {
            var sy:Float = y * srcHeight / dstHeight;
            var ry:Float = sy % 1;
            for (x in 0...dstWidth) {
                var sx:Float = x * srcWidth / dstWidth;
                var rx:Float = sx % 1;
                var val:Float = 0;
                val += src[Std.int(sy    ) * srcWidth + Std.int(sx    )] * (1 - rx) * (1 - ry);
                val += src[Std.int(sy    ) * srcWidth + Std.int(sx + 1)] * (    rx) * (1 - ry);
                val += src[Std.int(sy + 1) * srcWidth + Std.int(sx    )] * (1 - rx) * (    ry);
                val += src[Std.int(sy + 1) * srcWidth + Std.int(sx + 1)] * (    rx) * (    ry);
                dst[y * dstWidth + x] = val;
            }
        }
        return dst;
    }

    static function makeGlyphImage(width:UInt, height:UInt, src:Array<Float>):Image {
        var max:Float = 0;
        for (float in src) if (float != Math.POSITIVE_INFINITY && max < float) max = float;
        var image = new Image(null, 0, 0, width, height, 0x00FF00FF);
        for (y in 0...height) {
            for (x in 0...width) {
                var sdf = src[y * width + x];
                if (sdf == Math.POSITIVE_INFINITY) {
                    image.setPixel32(x, y, 0xFF0000FF);
                    continue;
                }
                var val = Std.int(Math.abs(sdf) / max * 0xFF);
                if (sdf > 0) val = val << 24;
                else val = (val << 16) | (val << 8);
                image.setPixel32(x, y, val | 0xFF);
            }
        }
        return image;
    }
}
