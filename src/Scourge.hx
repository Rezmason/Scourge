package;

import haxe.Utf8;

import openfl.Assets;
import flash.Lib;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display.StageQuality;
import flash.events.Event;

import net.rezmason.utils.FlatFont;

import net.rezmason.scourge.textview.TestStrings;

// import net.rezmason.scourge.textview.styles.StyleSet;

class Scourge {

    public function new() {

    }

    public static function main():Void {

        trace("\n" + TestStrings.SPLASH);

        Lib.current.stage.align = StageAlign.TOP_LEFT;
        //Lib.current.stage.quality = StageQuality.HIGH_16X16_LINEAR;
        // Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

        var fonts = new Map();

        for (name in ["source", "profont", "full"]) fonts[name] = makeFont(name);

        //var str = [TestStrings.SYMBOLS + " " + TestStrings.WEIRD_SYMBOLS, TestStrings.SPLASH, TestStrings.BOARD].join("\n\n");
        // var str = Assets.getText("assets/not plus.txt");
        // var str = Assets.getText("assets/enterprise.txt");
        var str = Assets.getText("assets/acid2.txt");
        // var str = TestStrings.STYLED_TEXT;
        // var str = "One. §{i:1}Two§{}.";

        new net.rezmason.scourge.textview.TextDemo(Lib.current.stage, fonts, str);

        /*
        var styleSet:StyleSet = new StyleSet();
        var page:String = styleSet.extractFromText(str);
        /**/
    }

    static function makeFont(id:String):FlatFont
    {
        var path:String = "assets/flatfonts/" + id + "_flat";
        return new FlatFont(Assets.getBitmapData(path + ".png"), Assets.getText(path + ".json"));
    }
}
