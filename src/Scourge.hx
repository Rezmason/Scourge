package;

import haxe.Utf8;

import haxe.ds.StringMap;

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

        var fonts:StringMap<FlatFont> = new StringMap<FlatFont>();

        for (name in ["source", "profont", "full"]) fonts.set(name, makeFont(name));

        //var str = [TestStrings.SYMBOLS + " " + TestStrings.WEIRD_SYMBOLS, TestStrings.SPLASH, TestStrings.BOARD].join("\n\n");
        //var str = Assets.getText("assets/not plus.txt");
        var str = TestStrings.STYLED_TEXT;
        new net.rezmason.scourge.textview.TextDemo(Lib.current.stage, fonts, str);
    }

    static function makeFont(id:String):FlatFont
    {
        var path:String = "assets/flatfonts/" + id + "_flat";
        return new FlatFont(Assets.getBitmapData(path + ".png"), Assets.getText(path + ".json"));
    }
}
