package net.rezmason.scourge.textview.text;

import haxe.Utf8;

using net.rezmason.utils.CharCode;

class Sigil {
    public inline static var STYLE:String = '§';
    public inline static var CARET:String = '¢';
    public inline static var ANIMATED_STYLE:String = '∂';
    public inline static var BUTTON_STYLE:String = 'µ';
    public inline static var INPUT_STYLE:String = '«';
    public inline static var PARAGRAPH_STYLE:String = '¶';

    public inline static var STYLE_CODE:Int = STYLE.code();
    public inline static var CARET_CODE:Int = CARET.code();
    public inline static var ANIMATED_STYLE_CODE:Int = ANIMATED_STYLE.code();
    public inline static var BUTTON_STYLE_CODE:Int = BUTTON_STYLE.code();
    public inline static var INPUT_STYLE_CODE:Int = INPUT_STYLE.code();
    public inline static var PARAGRAPH_STYLE_CODE:Int = PARAGRAPH_STYLE.code();
}
