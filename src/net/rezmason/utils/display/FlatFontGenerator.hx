package net.rezmason.utils.display;

import haxe.Utf8;
import haxe.io.BytesOutput;
import lime.Assets;
import lime.graphics.Image;
import lime.math.Rectangle;
import net.rezmason.math.FelzenszwalbSDF;

using net.rezmason.utils.Alphabetizer;

typedef GlyphData = {
    var image:Image;
    var bounds:Rectangle;
};

typedef CharacterSet = {
    var fontID:String;
    var chars:String;
    var size:Int;
    var size2:Int;
}

class FlatFontGenerator {

    public static function flatten(characterSets:Array<CharacterSet>, glyphWidth, glyphHeight, spacing, range, cbk) {

        var pendingGlyphs:Map<String, GlyphData> = new Map();
        var computedGlyphs:Map<String, Array<Float>> = new Map();
        var totalBounds:Rectangle = null;

        for (characterSet in characterSets) {
            var font = Assets.getFont(characterSet.fontID);
            for (index in 0...Utf8.length(characterSet.chars)) {
                var char = Utf8.sub(characterSet.chars, index, 1);
                if (pendingGlyphs.exists(char)) continue;
                var glyph = font.getGlyph(char);
                if (glyph == 0) continue;
                var renderedGlyph = font.renderGlyph(glyph, characterSet.size);
                if (renderedGlyph == null) continue;

                // Based on explanation at http://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
                var metrics = font.getGlyphMetrics(glyph);
                var unit = renderedGlyph.height / metrics.height;
                var offsetX = Std.int(metrics.horizontalBearing.x * unit);
                var offsetY = Std.int(characterSet.size2 - metrics.horizontalBearing.y * unit);

                var bounds = renderedGlyph.rect;
                bounds.x = offsetX;
                bounds.y = offsetY;
                pendingGlyphs[char] = {image:renderedGlyph, bounds:bounds};
                if (totalBounds == null) totalBounds = bounds;
                else totalBounds = totalBounds.union(bounds);
            }
        }

        totalBounds.left = Math.floor(totalBounds.left);
        totalBounds.top = Math.floor(totalBounds.top);
        totalBounds.right = Math.ceil(totalBounds.right);
        totalBounds.bottom = Math.ceil(totalBounds.bottom);

        var totalWidth = Std.int(totalBounds.width);
        var totalHeight = Std.int(totalBounds.height);
        var offsetX = Std.int(-totalBounds.x);
        var offsetY = Std.int(-totalBounds.y);

        var sdfWidth  = totalWidth + 2 * range;
        var sdfHeight = totalHeight + 2 * range;
        var numChars = 1;
        computedGlyphs[' '] = [for (ike in 0...glyphWidth * glyphHeight) cast range];
        for (char in pendingGlyphs.keys().a2z()) {
            var pendingGlyph = pendingGlyphs[char];
            var data = pendingGlyph.image.data;
            var sdfInput = [for (ike in 0...sdfWidth * sdfHeight) 0.];
            for (y in 0...pendingGlyph.image.height) {
                for (x in 0...pendingGlyph.image.width) {
                    var val:UInt = data[(y * pendingGlyph.image.width + x) * 1];
                    var outputX = Std.int(x + pendingGlyph.bounds.x + range + offsetX);
                    var outputY = Std.int(y + pendingGlyph.bounds.y + range + offsetY);
                    sdfInput[outputY * sdfWidth + outputX] = val == 0 ? 0 : 1;
                }
            }

            var sdfOutput = FelzenszwalbSDF.computeSignedDistanceField(sdfWidth, sdfHeight, sdfInput);
            // var sdfOutput = sdfInput;
            sdfOutput = resize(sdfWidth, sdfHeight, sdfOutput, glyphWidth, glyphHeight);
            
            numChars++;
            computedGlyphs[char] = sdfOutput;
            Sys.print(char);
        }

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
        output.writeUInt16(totalWidth);
        output.writeUInt16(totalHeight);
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
            output.writeFloat(xOffset / tableWidth);
            output.writeFloat(yOffset / tableHeight);
            col++;
            if (col >= numColumns) {
                col = 0;
                row++;
            }
        }

        for (float in table) output.writeUInt16(HalfFloatUtil.floatToHalfFloat(float));
        /*
        var halfFloats:Map<UInt, Bool> = new Map();
        var count = 0;
        for (float in table) {
            var halfFloat = HalfFloatUtil.floatToHalfFloat(float);
            if (!halfFloats.exists(halfFloat)) count++;
            halfFloats[halfFloat] = true;
        }
        trace(count);
        */
        Sys.print('\n');

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
