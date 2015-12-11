package net.rezmason.hypertype;

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

    public inline static var SYMBOLS:String = '<>[]{}-=!@#$$%^*()_+';
    public inline static var WEIRD_SYMBOLS:String = '¤¬øΔΩ•◊';
    
    //public inline static var BOX_SYMBOLS:String = ' ╵╶└╷│┌├╴┘─┴┐┤┬┼';
    public inline static var BOX_SYMBOLS:String = ' ╵╶╰╷│╭├╴╯─┴╮┤┬┼';
    
    public inline static var BOTTOM_LEFT = '╰';
    public inline static var BOTTOM_RIGHT = '╯';
    public inline static var TOP_LEFT = '╭';
    public inline static var TOP_RIGHT = '╮';
    public inline static var HORIZONTAL = '─';
    public inline static var VERTICAL = '│';
}