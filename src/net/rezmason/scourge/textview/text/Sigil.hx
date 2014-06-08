package net.rezmason.scourge.textview.text;

import haxe.Utf8;

using net.rezmason.utils.CharCode;

class Sigil {
    public inline static var STYLE:String = '§';
    public inline static var CARET:String = '¢';
    public inline static var ANIMATED_STYLE:String = '∂';
    public inline static var BUTTON_STYLE:String = 'µ';
    public inline static var INPUT_STYLE:String = '«';

    public inline static var STYLE_CODE:Int = '§'.code();
    public inline static var CARET_CODE:Int = '¢'.code();
    public inline static var ANIMATED_STYLE_CODE:Int = '∂'.code();
    public inline static var BUTTON_STYLE_CODE:Int = 'µ'.code();
    public inline static var INPUT_STYLE_CODE:Int = '«'.code();
}
