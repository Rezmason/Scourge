package net.rezmason.scourge.textview.text;

import haxe.Utf8;

class Sigil {
    public inline static var STYLE:String = '§';
    public inline static var ANIMATED_STYLE:String = '∂';
    public inline static var BUTTON_STYLE:String = 'µ';
    public inline static var INPUT_STYLE:String = '«';

    public static var STYLE_CODE:Int = getCode('§');
    public static var ANIMATED_STYLE_CODE:Int = getCode('∂');
    public static var BUTTON_STYLE_CODE:Int = getCode('µ');
    public static var INPUT_STYLE_CODE:Int = getCode('«');

    macro static function getCode(sigil:String) return macro $v{Utf8.charCodeAt(sigil, 0)};
}
