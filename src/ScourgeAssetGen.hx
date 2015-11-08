package;

import haxe.Utf8;
import haxe.io.BytesOutput;
import haxe.io.Bytes;

import lime.Assets;
import lime.app.Application;
import lime.graphics.Image;
import lime.math.Rectangle;
import lime.math.Vector2;

import format.png.Tools;
import format.png.Writer;

import net.rezmason.utils.display.SDF;

// import flash.Lib;
// import flash.display.Bitmap;
// import flash.display.BitmapData;
// import flash.display.Sprite;
// import flash.events.Event;
// import flash.text.Font;

// import flash.net.FileReference;

import net.rezmason.utils.display.FlatFont;
import net.rezmason.utils.display.FlatFontGenerator;
// import net.rezmason.utils.display.MetaballTextureGenerator;
// import net.rezmason.utils.display.GlobTextureGenerator;

import net.rezmason.scourge.Strings;

using net.rezmason.utils.Alphabetizer;

// @:font("assets/fonts/ProFontX.ttf") class ProFont extends Font {}
// @:font("assets/fonts/werf - Profont Cyrillic/werfProFont.ttf") class ProFont_Cy extends Font {}
// @:font("assets/fonts/SourceCodePro_FontsOnly-1.013/TTF/SourceCodePro-Semibold.ttf") class SourceProFont extends Font {}

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

class ScourgeAssetGen extends Application {

    override public function onPreloadComplete():Void {
        
        var profontChars:String = [
            Strings.ALPHANUMERICS,
            Strings.PUNCTUATION,
            Strings.SYMBOLS,
            Strings.WEIRD_SYMBOLS,
        ].join("");

        var characterSets:Array<CharacterSet> = [
            {chars:profontChars, size:300, size2:300, fontID:'ProFont'},
            {chars:Strings.SMALL_CYRILLICS, size:400, size2:300, fontID:'ProFont_Cy'},
            {chars:Strings.BOX_SYMBOLS, size:300, size2:300, fontID:'SourceProFont'},
        ];

        /*
        var current:Sprite = Lib.current;
        current.stage.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, function(e) {
            if (current.width <= current.stage.stageWidth) current.x = 0;
            else current.x = (current.stage.mouseX / current.stage.stageWidth ) * (current.stage.stageWidth  - current.width );

            if (current.height <= current.stage.stageHeight) current.y = 0;
            else current.y = (current.stage.mouseY / current.stage.stageHeight) * (current.stage.stageHeight - current.height);
        });
        
        FlatFontGenerator.flatten(sets, 72, 72, 1, 20, deployFont.bind(_, "full"));
        MetaballTextureGenerator.makeTexture(30, 0.62, 20, deployImage.bind(_, "metaball"));
        GlobTextureGenerator.makeTexture(512, deployImage.bind(_, "glob"));
        */

        flatten(characterSets, 72, 72, 1, 20, 20, deployFont.bind(_, 'full'));

        Sys.exit(0);
    }

    static function flatten(characterSets:Array<CharacterSet>, glyphWidth, glyphHeight, spacing, leeway, cutoff, cbk) {

        var renderedGlyphs:Map<String, Image> = new Map();
        var numChars = 0;
        var includeSpace = false;

        for (characterSet in characterSets) {
            var fontID = characterSet.fontID;
            var chars = characterSet.chars;
            var fontSize = characterSet.size;
            var fontSize2 = characterSet.size2;
            var maxWidth = 0;
            var maxHeight = 0;
            var font = Assets.getFont(fontID);
            var pendingGlyphs:Map<String, PendingGlyph> = new Map();

            for (ike in 0...Utf8.length(chars)) {
                var char = Utf8.sub(chars, ike, 1);
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
        for (char in renderedGlyphs.keys().a2z()) {
            var renderedGlyph = renderedGlyphs[char];
            dest.x = col * (glyphWidth  + spacing);
            dest.y = row * (glyphHeight + spacing);
            output.copyPixels(renderedGlyph, renderedGlyph.rect, dest);
            col++;
            if (col >= numColumns) {
                col = 0;
                row++;
            }
        }

        cbk(output/*new FlatFont(outputData, json.stringify())*/);
    }

    static function deployFont(image:Image /*font:FlatFont*/, id:String):Void {

        sys.io.File.saveContent('../../../../../../../../assets/flatfonts/${id}_flat_new.png', image.encode().toString());

        /*
        var fontBD:BitmapData = @:privateAccess font.getImageClone().buffer.__srcBitmapData;

        var sprite:Sprite = new Sprite();
        sprite.addChild(new Bitmap(fontBD));

        var fileRef = null;
        sprite.addEventListener("click", function(_) {
            var json = font.exportJSON();

            var bytesOutput:BytesOutput = new BytesOutput();
            var writer:Writer = new Writer(bytesOutput);
            var data = Tools.build32ARGB(fontBD.width, fontBD.height, Bytes.ofData(fontBD.getPixels(fontBD.rect)));
            writer.write(data);

            fileRef = new FileReference();

            function savePNG(_) {
                fileRef.removeEventListener("complete", savePNG);
                fileRef.save(bytesOutput.getBytes().getData(), id + "_flat.png");
                Lib.current.removeChild(sprite);
            }

            fileRef.addEventListener("complete", savePNG);
            fileRef.save(json, id + "_flat.json");

        });

        Lib.current.addChild(sprite);
        */
    }

    static function deployImage(/*image:BitmapData,*/ id:String):Void {
        /*
        var sprite:Sprite = new Sprite();
        sprite.addChild(new Bitmap(image));
        var fileRef = null;
        sprite.addEventListener("click", function(_) {
            var bytesOutput:BytesOutput = new BytesOutput();
            var writer:Writer = new Writer(bytesOutput);
            var data = Tools.build32ARGB(image.width, image.height, Bytes.ofData(image.getPixels(image.rect)));
            writer.write(data);
            fileRef = new FileReference();
            fileRef.save(bytesOutput.getBytes().getData(), id + ".png");
            Lib.current.removeChild(sprite);
        });

        Lib.current.addChild(sprite);
        */
    }
}
