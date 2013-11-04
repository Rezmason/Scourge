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

import net.rezmason.utils.FlatFont;
import net.rezmason.utils.FlatFontGenerator;

import net.rezmason.scourge.textview.TestStrings;

@:font("assets/ProFontX.ttf") class ProFont extends Font {}
@:font("assets/SourceCodePro_FontsOnly-1.013/TTF/SourceCodePro-Semibold.ttf") class SourceProFont extends Font {}

class ScourgeAssetGen {

    static var font1:FlatFont = null;
    static var font2:FlatFont = null;

    public static function main():Void {

        var requiredString:String = [
            TestStrings.ALPHANUMERICS,
            TestStrings.PUNCTUATION,
            TestStrings.SYMBOLS,
            TestStrings.WEIRD_SYMBOLS,
            TestStrings.BOX_SYMBOLS,
        ].join("");

        FlatFontGenerator.flatten(new ProFont(), 300, requiredString, 72, 72, 1, 20, function(ff) {
            font1 = ff;
            if (font1 != null && font2 != null) proceed();
        });

        FlatFontGenerator.flatten(new SourceProFont(), 300, requiredString, 72, 72, 1, 20, function(ff) {
            font2 = ff;
            if (font1 != null && font2 != null) proceed();
        });
    }

    static function proceed():Void {
        var font3:FlatFont = FlatFontGenerator.combine(font1, [font2]);

        deploy(font1, "profont");
        deploy(font2, "source");
        deploy(font3, "full");
    }

    static function deploy(font:FlatFont, id:String):Void {
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
}
