package net.rezmason.scourge.textview;

import haxe.ds.IntMap;
import net.rezmason.utils.FatChar;

class TestStrings {

    public inline static var SPLASH:String =
        " SSSSS    CCCCC    OOOOO   UU   UU  RRRRRR    GGGGG    EEEEE " +
        "SS       CC   CC  OO   OO  UU   UU  RR   RR  GG       EE   EE" +
        "SSSSSSS  CC       OO   OO  UU   UU  RRRRRR   GG  GGG  EEEEEEE" +
        "     SS  CC   CC  OO   OO  UU   UU  RR   RR  GG   GG  EE     " +
        " SSSSS    CCCCC    OOOOO    UUUUU   RR   RR   GGGGG    EEEEE " +
        "" +
        "Single-Celled  Organisms  Undergo  Rapid  Growth  Enhancement" +
    "\n";

    public inline static var SYMBOLS:String = "()<>@[]_{}#$*";
    public inline static var WEIRD_SYMBOLS:String = "¤¬ÎøΔΩ•◊";

    public inline static var BOARD:String =
        "X X X X X X X X X X X X X X X X X X X X X X X X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X           1                     2           X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X           0                     3           X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X                                             X" +
        "X X X X X X X X X X X X X X X X X X X X X X X X" +
    "\n";

    public inline static var ALPHANUMERICS:String =
        "abcdefghijklmnopqrstuvwxyz" +
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
        "0123456789" +
        "";

    public inline static function CHAR_COLORS():IntMap<Int> {
        var colors:IntMap<Int> = new IntMap<Int>();
        colors.set(FatChar.fromString("S")[0].code, 0xFF0090);
        colors.set(FatChar.fromString("C")[0].code, 0xFFC800);
        colors.set(FatChar.fromString("O")[0].code, 0x30FF00);
        colors.set(FatChar.fromString("U")[0].code, 0x00C0FF);
        colors.set(FatChar.fromString("R")[0].code, 0xFF6000);
        colors.set(FatChar.fromString("G")[0].code, 0xC000FF);
        colors.set(FatChar.fromString("E")[0].code, 0x0030FF);
        return colors;
    }
}
