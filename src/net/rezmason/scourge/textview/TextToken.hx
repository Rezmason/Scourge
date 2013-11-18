package net.rezmason.scourge.textview;

enum TextToken {
    PLAIN_TEXT(text:String);
    HINT_COMMENT(text:String);
    HINT_SHORTCUT(caption:String, text:String);
    SHORTCUT(caption:String, text:String);
    EMPTY_CAPSULE(type:CommandCodeType, caption:String);
    INCOMPLETE_CAPSULE(type:CommandCodeType, valid:Bool);
    COMPLETE_CAPSULE(type:CommandCodeType, valid:Bool);
}
