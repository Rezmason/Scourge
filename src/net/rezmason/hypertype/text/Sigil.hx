package net.rezmason.hypertype.text;

import haxe.Utf8;

using net.rezmason.utils.CharCode;

class Sigil {
    public inline static var STYLE_SIGIL:String = '§';
    public inline static var CARET_SIGIL:String = '¢';
    public inline static var ANIMATED_STYLE_SIGIL:String = '∂';
    public inline static var BUTTON_STYLE_SIGIL:String = 'µ';
    public inline static var INPUT_STYLE_SIGIL:String = '«';
    public inline static var PARAGRAPH_STYLE_SIGIL:String = '¶';

    public inline static var STYLE_SIGIL_CODE:Int = STYLE_SIGIL.code();
    public inline static var CARET_SIGIL_CODE:Int = CARET_SIGIL.code();
    public inline static var ANIMATED_STYLE_SIGIL_CODE:Int = ANIMATED_STYLE_SIGIL.code();
    public inline static var BUTTON_STYLE_SIGIL_CODE:Int = BUTTON_STYLE_SIGIL.code();
    public inline static var INPUT_STYLE_SIGIL_CODE:Int = INPUT_STYLE_SIGIL.code();
    public inline static var PARAGRAPH_STYLE_SIGIL_CODE:Int = PARAGRAPH_STYLE_SIGIL.code();
}
