import nme.Lib;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.events.Event;

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

        var hash:Hash<Int> = new Hash<Int>();

        hash.set("S", 0xFF0090);
        hash.set("C", 0xFFC800);
        hash.set("O", 0x30FF00);
        hash.set("U", 0x00C0FF);
        hash.set("R", 0xFF6000);
        hash.set("G", 0xC000FF);
        hash.set("E", 0x0030FF);
        //hash.set(" ", 0x606060);

        Lib.trace(splash.join("\n"));

        Lib.current.stage.align = StageAlign.TOP_LEFT;
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

        var str = ["{}lgÖ", symbols.join("\n"), splash.join("\n")].join("\n");

        //new net.rezmason.scourge.view.TextThing(Lib.current, str, hash);
        //new net.rezmason.scourge.view.BoardThing(Lib.current, str, hash);

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

        new net.rezmason.scourge.view.FontBlitThing(Lib.current, str, hash);
    }
}
