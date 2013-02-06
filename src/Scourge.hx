package;

import haxe.Utf8;

import nme.Assets;
import nme.Lib;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.events.Event;

import net.rezmason.utils.FlatFont;
import net.rezmason.utils.FatChar;

import net.rezmason.scourge.textview.TestStrings;

class Scourge {

    public function new() {

    }

    public static function main():Void {

        Lib.trace("\n" + TestStrings.SPLASH);

        var colors:IntHash<Int> = new IntHash<Int>();
        colors.set(FatChar.fromString("S")[0].code, 0xFF0090);
        colors.set(FatChar.fromString("C")[0].code, 0xFFC800);
        colors.set(FatChar.fromString("O")[0].code, 0x30FF00);
        colors.set(FatChar.fromString("U")[0].code, 0x00C0FF);
        colors.set(FatChar.fromString("R")[0].code, 0xFF6000);
        colors.set(FatChar.fromString("G")[0].code, 0xC000FF);
        colors.set(FatChar.fromString("E")[0].code, 0x0030FF);

        Lib.current.stage.align = StageAlign.TOP_LEFT;
        Lib.current.stage.scaleMode = StageScaleMode.EXACT_FIT;

        var str = [TestStrings.SYMBOLS + " " + TestStrings.WEIRD_SYMBOLS, TestStrings.SPLASH, TestStrings.BOARD].join("\n\n");

        var flatFont = new FlatFont(Assets.getBitmapData("assets/profont_flat.png"), Assets.getText("assets/profont_flat.json"));

        /*

        var requiredString:String = [
            TestStrings.ALPHANUMERICS,
            TestStrings.SYMBOLS,
            TestStrings.WEIRD_SYMBOLS,
        ].join("");

        var flatFont = FlatFont.flatten(Assets.getFont("assets/ProFontX.ttf"), requiredString, 64, 64, 2);

        var fileRef = null;
        Lib.current.stage.addEventListener("click", function(_) {
            var json = flatFont.exportJSON();
            var pngBytes = com.moodycamel.PNGEncoder2.encode(flatFont.getBitmapDataClone());
            fileRef = new flash.net.FileReference();

            function savePNG(_) {
                fileRef.removeEventListener("complete", savePNG);
                fileRef.save(pngBytes, "profont_flat.png");
            }

            fileRef.addEventListener("complete", savePNG);
            fileRef.save(json, "profont_flat.json");
        });
        /**/

        //new net.rezmason.scourge.textview.TextView(Lib.current, str, colors, flatFont).start();
        new net.rezmason.scourge.textview.TextBlitter(Lib.current, str, colors, flatFont);
    }
}
