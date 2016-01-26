package net.rezmason.utils.display;

import haxe.Utf8;
import haxe.io.BytesOutput;
import lime.Assets;
import lime.graphics.Image;
import lime.math.Rectangle;
import net.rezmason.math.FelzenszwalbSDF;

using net.rezmason.utils.Alphabetizer;

typedef GlyphData = {
    var data:Array<Bool>;
    var bounds:Rectangle;
};

typedef FontCharacterSet = {
    var fontID:String;
    var chars:String;
    var size:Int;
    var size2:Int;
}

typedef ImageCharacterSet = {
    var imageID:String;
    var chars:String;
    var rows:UInt;
    var columns:UInt;
};

class SDFFontGenerator {

    public static function extractGlyphsFromFonts(characterSets:Array<FontCharacterSet>):Map<String, GlyphData> {
        var glyphs:Map<String, GlyphData> = new Map();
        for (characterSet in characterSets) {
            var font = Assets.getFont(characterSet.fontID);
            for (index in 0...Utf8.length(characterSet.chars)) {
                var char = Utf8.sub(characterSet.chars, index, 1);
                if (glyphs.exists(char) || char == ' ') continue;
                var glyph = font.getGlyph(char);
                if (glyph == 0) continue;
                var image = font.renderGlyph(glyph, characterSet.size);
                if (image == null) continue;

                // Based on explanation at http://www.freetype.org/freetype2/docs/glyphs/glyphs-3.html
                var metrics = font.getGlyphMetrics(glyph);
                var unit = image.height / metrics.height;
                var offsetX = Std.int(metrics.horizontalBearing.x * unit);
                var offsetY = Std.int(characterSet.size2 - metrics.horizontalBearing.y * unit);

                var bounds = image.rect;
                bounds.x = offsetX;
                bounds.y = offsetY;

                var data = [for (val in image.data) val != 0];

                glyphs[char] = {data:data, bounds:bounds};
            }
        }
        return glyphs;
    }

    public static function extractGlyphsFromImages(characterSets:Array<ImageCharacterSet>):Map<String, GlyphData> {
        var glyphs:Map<String, GlyphData> = new Map();
        for (characterSet in characterSets) {
            var atlas = Assets.getImage(characterSet.imageID);
            var glyphWidth:UInt = Std.int(atlas.width / characterSet.columns);
            var glyphHeight:UInt = Std.int(atlas.height / characterSet.rows);
            var image = new Image(null, 0, 0, glyphWidth, glyphHeight, 0x0);
            var rect = image.rect;
            var bounds = image.rect;
            var topLeft = new lime.math.Vector2(0, 0);
            var row = 0;
            var column = 0;
            for (index in 0...Utf8.length(characterSet.chars)) {
                var char = Utf8.sub(characterSet.chars, index, 1);
                if (!(glyphs.exists(char) || char == ' ')) {
                    rect.x = glyphWidth * column;
                    rect.y = glyphHeight * row;
                    image.copyPixels(atlas, rect, topLeft);
                    var data = [];
                    for (ike in 0...glyphWidth * glyphHeight) {
                        var val = 0;
                        val = val | image.data[ike * 4 + 0]; // R
                        val = val | image.data[ike * 4 + 1]; // G
                        val = val | image.data[ike * 4 + 2]; // B
                        // val = val | image.data[ike * 4 + 3]; // A
                        data[ike] = val != 0;
                    }
                    glyphs[char] = {data:data, bounds:bounds};
                }
                column++;
                if (column >= characterSet.columns) {
                    column = 0;
                    row++;
                    if (row > characterSet.rows) {
                        break;
                    }
                }
            }
        }
        return glyphs;
    }

    static function charFor(val:Float):String {
        var isNeg = val < 0;
        var char = String.fromCharCode(65 + Std.int(Math.abs(val)));
        if (isNeg) char = char.toLowerCase();
        return char;
    }

    public static function generate(glyphs:Map<String, GlyphData>, glyphWidth, glyphHeight, spacing, range, cbk) {
        var computedGlyphs:Map<String, Array<Float>> = new Map();
        var totalBounds:Rectangle = null;

        for (glyph in glyphs) {
            if (totalBounds == null) totalBounds = glyph.bounds;
            else totalBounds = totalBounds.union(glyph.bounds);
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
        for (char in glyphs.keys().a2z()) {
            var glyph = glyphs[char];
            var glyphBounds = glyph.bounds;
            var glyphData = glyph.data;
            var sdfInput = [for (ike in 0...sdfWidth * sdfHeight) 0.];
            for (y in 0...Std.int(glyphBounds.height)) {
                for (x in 0...Std.int(glyphBounds.width)) {
                    var outputX = Std.int(x + glyphBounds.x + range + offsetX);
                    var outputY = Std.int(y + glyphBounds.y + range + offsetY);
                    var val = glyphData[(y * Std.int(glyphBounds.width) + x)] ? 1 : 0;
                    sdfInput[outputY * sdfWidth + outputX] = val;
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
