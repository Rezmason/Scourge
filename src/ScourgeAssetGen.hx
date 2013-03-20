package;

import haxe.Utf8;

import nme.Assets;
import nme.Lib;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.events.Event;

import net.rezmason.utils.FlatFont;

import net.rezmason.scourge.textview.TestStrings;

class ScourgeAssetGen {

    public static function main():Void {

        var requiredString:String = [
            TestStrings.ALPHANUMERICS,
            TestStrings.SYMBOLS,
            TestStrings.WEIRD_SYMBOLS,
        ].join("");

        var flatFont = FlatFont.flatten(Assets.getFont("assets/ProFontX.ttf"), 140, requiredString, 48, 48, 2);
        var fontBD:BitmapData = flatFont.getBitmapDataClone();

        var fileRef = null;
        Lib.current.stage.addEventListener("click", function(_) {
            var json = flatFont.exportJSON();
            var pngBytes = com.moodycamel.PNGEncoder2.encode(fontBD);
            fileRef = new flash.net.FileReference();

            function savePNG(_) {
                fileRef.removeEventListener("complete", savePNG);
                fileRef.save(pngBytes, "profont_flat.png");
            }

            fileRef.addEventListener("complete", savePNG);
            fileRef.save(json, "profont_flat.json");
        });

        Lib.current.addChild(new Bitmap(fontBD));
    }
}
