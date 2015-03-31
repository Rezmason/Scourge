package net.rezmason.scourge;

using net.rezmason.utils.CharCode;

class Strings {

    public inline static var SPACE:String = ' ';
    public inline static var SPACE_CODE:Int = SPACE.code();
    public inline static var HARD_SPACE:String = ' ';
    public inline static var HARD_SPACE_CODE:Int = HARD_SPACE.code();

    public inline static var ALPHANUMERICS:String =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789' +
        '';
    public inline static var PUNCTUATION:String = '\'\"?!.,;:-~/\\`|&';
    public inline static var SMALL_CYRILLICS:String = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
    public inline static var CYRILLICS:String = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ' + SMALL_CYRILLICS;

    public inline static var SYMBOLS:String = '<>[]{}-=!@#$%^*()_+';
    public inline static var WEIRD_SYMBOLS:String = '¤¬øΔΩ•◊';
    
    //public inline static var BOX_SYMBOLS:String = ' ╹╺┗╻┃┏┣╸┛━┻┓┫┳╋';
    //public inline static var BOX_SYMBOLS:String = ' ╹╺╰╻┃╭┣╸╯━┻╮┫┳╋';
    //public inline static var BOX_SYMBOLS:String = ' ╵╶└╷│┌├╴┘─┴┐┤┬┼';
    public inline static var BOX_SYMBOLS:String = ' ╵╶╰╷│╭├╴╯─┴╮┤┬┼';
    public inline static var BODY_GLYPHS:String = ' пгчцълкпрншьэмх';

    public inline static var BOARD_CODE:Int = '+'.code(); // ¤
    public inline static var WALL_CODE:Int = '╋'.code();
    public inline static var CAVITY_CODE:Int = 'ж'.code();
    public inline static var BODY_CODE:Int = '•'.code();
    public inline static var HEAD_CODE:Int = 'Ω'.code();
    public inline static var UI_CODE:Int = ''.code();
    public inline static var BLANK_CODE:Int = ' '.code();
}
