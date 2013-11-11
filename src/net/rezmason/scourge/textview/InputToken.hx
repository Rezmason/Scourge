package net.rezmason.scourge.textview;

enum InputToken {
    PLAIN_TEXT(text:String);
    HINT_COMMENT(text:String);
    HINT_SHORTCUT(caption:String, text:String);
    SHORTCUT(caption:String, text:String);
    INCOMPLETE_CAPSULE(type:TokenType, valid:Bool);
    COMPLETE_CAPSULE(type:TokenType, valid:Bool);
}
