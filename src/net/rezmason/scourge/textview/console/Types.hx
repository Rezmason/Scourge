package net.rezmason.scourge.textview.console;

class CommandCodeRestriction {
    public inline static var ROTATION_NOTATION:String = 'yuioYUIO';
    public inline static var NODE_CODE:String = '01234567890abcdefABCDEF';
    public inline static var CRAWL_SCRAWL:String = 'qweasdzxcQWEASDZXC';
}

typedef TextToken = {
    var text:String;
    @:optional var styleName:String;
    @:optional var restriction:String;
    @:optional var payload:Dynamic;
    @:optional var id:String;
    @:optional var authorID:Int;
}

typedef HintCallback = Array<TextToken> -> Int -> Int -> Array<TextToken> -> Void;
typedef ExecCallback = Array<TextToken> -> Bool -> Void;

typedef InputInfo = {
    var tokenIndex:Int;
    var caretIndex:Int;
    var char:String;
}
