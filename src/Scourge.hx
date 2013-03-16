package;

import haxe.Utf8;

import nme.Assets;
import nme.Lib;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.display.StageQuality;
import nme.events.Event;

import net.rezmason.utils.FlatFont;

import net.rezmason.scourge.textview.TestStrings;

class Scourge {

    public function new() {

    }

    public static function main():Void {

        Lib.trace("\n" + TestStrings.SPLASH);

        Lib.current.stage.align = StageAlign.TOP_LEFT;
        //Lib.current.stage.quality = StageQuality.HIGH_16X16_LINEAR;
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

        var str = [TestStrings.SYMBOLS + " " + TestStrings.WEIRD_SYMBOLS, TestStrings.SPLASH, TestStrings.BOARD].join("\n\n");
        var flatFont = new FlatFont(Assets.getBitmapData("assets/profont_flat.png"), Assets.getText("assets/profont_flat.json"));
        //new net.rezmason.scourge.textview.TextBlitter(Lib.current.stage, str, TestStrings.CHAR_COLORS, flatFont);
        new net.rezmason.scourge.textview.Stage3DFuckbox(Lib.current.stage, flatFont);
    }
}
