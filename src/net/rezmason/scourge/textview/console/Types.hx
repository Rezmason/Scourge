package net.rezmason.scourge.textview.console;

enum TokenType {
    PLAIN_TEXT;
    SHORTCUT(insert:Array<TextToken>);
    CAPSULE(type:CommandCodeType, name:String, valid:Bool);
}

enum CommandCodeType {
    ROTATION_NOTATION;
    NODE_CODE;
    CRAWL_SCRAWL;
}

typedef TextToken = {
    var text:String;
    var type:TokenType;
    @:optional var styleName:String;
}

typedef HintCallback = Array<TextToken> -> Int -> Int -> Array<TextToken> -> Void;
typedef ExecCallback = Array<TextToken> -> Bool -> Void;

typedef InputInfo = {
    var tokenIndex:Int;
    var caretIndex:Int;
    var char:String;
}
