package;

import haxe.Utf8;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import format.png.Tools;
import format.png.Writer;
import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.Font;

import flash.net.FileReference;

import net.rezmason.utils.display.FlatFont;
import net.rezmason.utils.display.FlatFontGenerator;
import net.rezmason.utils.display.MetaballTextureGenerator;

import net.rezmason.scourge.Strings;

@:font("assets/fonts/ProFontX.ttf") class ProFont extends Font {}
@:font("assets/fonts/werf - Profont Cyrillic/werfProFont.ttf") class ProFont_Cy extends Font {}
@:font("assets/fonts/SourceCodePro_FontsOnly-1.013/TTF/SourceCodePro-Semibold.ttf") class SourceProFont extends Font {}

class ScourgeAssetGen {

    public static function main():Void {

        var current:Sprite = Lib.current;
        current.stage.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, function(e) {
            if (current.width <= current.stage.stageWidth) current.x = 0;
            else current.x = (current.stage.mouseX / current.stage.stageWidth ) * (current.stage.stageWidth  - current.width );

            if (current.height <= current.stage.stageHeight) current.y = 0;
            else current.y = (current.stage.mouseY / current.stage.stageHeight) * (current.stage.stageHeight - current.height);
        });
        
        var profontChars:String = [
            Strings.ALPHANUMERICS,
            Strings.PUNCTUATION,
            Strings.SYMBOLS,
            Strings.WEIRD_SYMBOLS,
        ].join("");

        var sets:Array<CharacterSet> = [
            {chars:profontChars, size:300, font:new ProFont()},
            {chars:Strings.SMALL_CYRILLICS, size:384, font:new ProFont_Cy()},
            {chars:Strings.BOX_SYMBOLS, size:300, font:new ScourgeAssetGen.SourceProFont()},
        ];
        FlatFontGenerator.flatten(sets, 72, 72, 1, 20, deployFont.bind(_, "full"));
        
        MetaballTextureGenerator.makeTexture(25, 25, deployImage.bind(_, "metaball"));

    }

    static function deployFont(font:FlatFont, id:String):Void {
        var fontBD:BitmapData = font.getBitmapDataClone();

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
    }

    static function deployImage(image:BitmapData, id:String):Void {
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
    }
}
