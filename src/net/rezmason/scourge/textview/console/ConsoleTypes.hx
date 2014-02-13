package net.rezmason.scourge.textview.console;

class CommandCodeRestriction {
    public inline static var ROTATION_NOTATION:String = 'yuioYUIO';
    public inline static var NODE_CODE:String = '01234567890abcdefABCDEF';
    public inline static var CRAWL_SCRAWL:String = 'qweasdzxcQWEASDZXC';
}

typedef ConsoleToken = {
    var text:String;
    var type:ConsoleTokenType;
    var next:ConsoleToken;
    var prev:ConsoleToken;
}

enum ConsoleTokenType {
    Key;
    Value;
    Flag;
    CommandName;
    Tail;
    TailMarker;
}

typedef ConsoleState = {
    var input:ConsoleToken;
    var output:ConsoleToken;
    var hint:ConsoleToken;
    var currentToken:ConsoleToken;
    var caretIndex:Int;

    @:optional var completionError:String;
    @:optional var hintError:String;
    @:optional var commandError:String;

    @:optional var autoTail:Bool;

    @:optional var currentCommand:ConsoleCommand;
    @:optional var keyReg:Map<String, Bool>;
    @:optional var flagReg:Map<String, Bool>;
    @:optional var tailMarkerPresent:Bool;

    @:optional var hints:Array<ConsoleHint>;
}

typedef ConsoleHint = {
    var text:String;
    var type:ConsoleTokenType;
}

typedef ConsoleCommandArgs = {
    var flags:Array<String>;
    var keyValuePairs:Map<String, String>;
    var user:String;
}
