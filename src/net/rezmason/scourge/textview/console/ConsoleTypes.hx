package net.rezmason.scourge.textview.console;

class CommandCodeRestriction {
    public inline static var ROTATION_NOTATION:String = 'yuioYUIO';
    public inline static var NODE_CODE:String = '01234567890abcdefABCDEF';
    public inline static var CRAWL_SCRAWL:String = 'qweasdzxcQWEASDZXC';
}

typedef ConsoleToken = {
    var text:String;
    @:optional var next:ConsoleToken;
    @:optional var prev:ConsoleToken;
    @:optional var invalidReason:String;
}

typedef ConsoleState = {
    var input:ConsoleToken;
    var output:ConsoleToken;
    var hint:ConsoleToken;
    var currentToken:ConsoleToken;
    var caretIndex:Int;
}
