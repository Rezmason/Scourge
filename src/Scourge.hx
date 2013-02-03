import nme.Assets;
import nme.Lib;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.events.Event;

import net.rezmason.utils.FlatFont;

class Scourge {

    public function new() {

    }

    public static function main():Void {
        var params:Dynamic = null;

        #if flash
            Lib.current.loaderInfo.parameters;
        #end

        var splash:Array<String> = [
            " SSSSS    CCCCC    OOOOO   UU   UU  RRRRRR    GGGGG    EEEEE ",
            "SS       CC   CC  OO   OO  UU   UU  RR   RR  GG       EE   EE",
            "SSSSSSS  CC       OO   OO  UU   UU  RRRRRR   GG  GGG  EEEEEEE",
            "     SS  CC   CC  OO   OO  UU   UU  RR   RR  GG   GG  EE     ",
            " SSSSS    CCCCC    OOOOO    UUUUU   RR   RR   GGGGG    EEEEE ",
            "",
            "Single-Celled  Organisms  Undergo  Rapid  Growth  Enhancement",
        ];

        var symbols:Array<String> = [
            "¬  > Ω Î @ Δ ◊ ¤ _ { } [ ] • ø",
            "' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '",
        ];

        var colors:Hash<Int> = new Hash<Int>();

        colors.set("S", 0xFF0090);
        colors.set("C", 0xFFC800);
        colors.set("O", 0x30FF00);
        colors.set("U", 0x00C0FF);
        colors.set("R", 0xFF6000);
        colors.set("G", 0xC000FF);
        colors.set("E", 0x0030FF);
        //colors.set(" ", 0x606060);

        Lib.trace(splash.join("\n"));

        Lib.current.stage.align = StageAlign.TOP_LEFT;
        Lib.current.stage.scaleMode = StageScaleMode.EXACT_FIT;

        var str = ["{}lgÖ", symbols.join("\n"), splash.join("\n")].join("\n");

        var boardString =
        "X X X X X X X X X X X X X X X X X X X X X X X X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X           1                     2           X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X           0                     3           X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X                                             X\n" +
        "X X X X X X X X X X X X X X X X X X X X X X X X";

        var requiredString:String = [
            str,
            "abcdefghijklmnopqrstuvwxyz",
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
            "0123456789"
        ].join("");

        var flatFont = FlatFont.flatten(Assets.getFont("assets/ProFontX.ttf"), requiredString, 64, 64);
        new net.rezmason.scourge.textview.TextBlitter(Lib.current, str, colors, flatFont);
        //new net.rezmason.scourge.textview.TextView(Lib.current, str, colors, flatFont).start();
    }
}
