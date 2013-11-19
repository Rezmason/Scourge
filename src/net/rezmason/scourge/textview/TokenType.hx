package net.rezmason.scourge.textview;

enum TokenType {
    PLAIN_TEXT;
    SHORTCUT(insert:Array<TextToken>);
    CAPSULE(type:CommandCodeType, caption:String, valid:Bool);
}
