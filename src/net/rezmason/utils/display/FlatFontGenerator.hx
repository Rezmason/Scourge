package net.rezmason.utils.display;

import haxe.Utf8;
import lime.Assets;
import lime.graphics.Image;
import lime.math.Rectangle;
import lime.math.Vector2;
import net.rezmason.utils.display.FlatFont;
import net.rezmason.utils.display.SDF;
using haxe.Json;
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

    public static function flatten(characterSets:Array<CharacterSet>, glyphWidth, glyphHeight, spacing, leeway, cutoff, cbk) {

        var renderedGlyphs:Map<String, Image> = new Map();
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
                if (renderedGlyphs.exists(char)) continue;
                
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

            maxWidth += 2 * leeway;
            maxHeight += 2 * leeway;

            if (ike == 0) glyphRatio = maxHeight / maxWidth;

            for (char in pendingGlyphs.keys().a2z()) {
                var pendingGlyph = pendingGlyphs[char];
                var properGlyphImage = new Image(null, 0, 0, maxWidth, maxHeight, 0x000000FF);
                var data = pendingGlyph.image.data;
                for (y in 0...pendingGlyph.image.height) {
                    for (x in 0...pendingGlyph.image.width) {
                        var val:UInt = data[(y * pendingGlyph.image.width + x) * 1];
                        properGlyphImage.setPixel32(
                            x + pendingGlyph.offsetX + leeway, 
                            y + pendingGlyph.offsetY + leeway, 
                            val == 0 ? 0x000000FF : 0xFFFFFFFF
                        );
                    }
                }
                properGlyphImage = new SDF(properGlyphImage, cutoff).output.clone();
                properGlyphImage.resize(glyphWidth, glyphHeight);
                numChars++;
                renderedGlyphs[char] = properGlyphImage;
                trace(char);
            }
        }

        if (includeSpace) renderedGlyphs[' '] = new Image(null, 0, 0, glyphWidth, glyphHeight, 0x0000FFFF);
        var numColumns:Int = Std.int(Math.sqrt(numChars)) + 1;
        var numRows:Int = Std.int(numChars / numColumns) + 1;
        var finalWidth  = numColumns * (glyphWidth  + spacing) - spacing;
        var finalHeight = numRows    * (glyphHeight + spacing) - spacing;
        var output = new Image(null, 0, 0, finalWidth, finalHeight, 0x0000FFFF);
        var row = 0;
        var col = 0;
        var dest = new Vector2();
        var charCoordJSON:Dynamic = {};
        for (char in renderedGlyphs.keys().a2z()) {
            var renderedGlyph = renderedGlyphs[char];
            dest.x = col * (glyphWidth  + spacing);
            dest.y = row * (glyphHeight + spacing);
            output.copyPixels(renderedGlyph, renderedGlyph.rect, dest);
            Reflect.setField(charCoordJSON, '_' + Utf8.charCodeAt(char, 0), {x: dest.x, y: dest.y});
            col++;
            if (col >= numColumns) {
                col = 0;
                row++;
            }
        }

        var json:FlatFontJSON = {
            glyphWidth:glyphWidth,
            glyphHeight:glyphHeight,
            glyphRatio:glyphRatio,
            charCoords:charCoordJSON,
        };

        cbk(new FlatFont(output, json.stringify()));
    }
}
