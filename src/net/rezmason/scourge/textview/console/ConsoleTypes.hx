package net.rezmason.scourge.textview.console;

class ConsoleRestriction {
    public inline static var ROTATION_NOTATION:String = 'yuioYUIO';
    public inline static var NODE_CODE:String = '01234567890abcdefABCDEF';
    public inline static var CRAWL_SCRAWL:String = 'qweasdzxcQWEASDZXC';

    public inline static var PLAYER_PATTERN:String = 'bhBH';
    public inline static var INTEGERS:String = '01234567890';
    public inline static var REALS:String = INTEGERS + '.';
    public inline static var LOWER_CASE:String = 'abcdefghijklmnopqrstuvwxyz';
    public inline static var UPPER_CASE:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    public inline static var ALPHANUMERICS:String = INTEGERS + LOWER_CASE + UPPER_CASE;
}

typedef ConsoleToken = {
    var text:String;
    var type:ConsoleTokenType;
    @:optional var next:ConsoleToken;
    @:optional var prev:ConsoleToken;
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

    @:optional var completeError:String;
    @:optional var finalError:String;
    @:optional var hintError:String;
    @:optional var commandError:String;

    @:optional var autoTail:Bool;

    @:optional var args:ConsoleCommandArgs;
    @:optional var currentCommand:ConsoleCommand;
    @:optional var keyReg:Map<String, Bool>;
    @:optional var flagReg:Map<String, Bool>;
    @:optional var tailMarkerPresent:Bool;

    @:optional var hints:Array<ConsoleToken>;
    @:optional var commandHints:Array<ConsoleToken>;
}

typedef ConsoleCommandArgs = {
    var flags:Array<String>;
    var keyValuePairs:Map<String, String>;
    var tail:String;

    @:optional var pendingKey:String;
    @:optional var pendingValue:String;
}

enum InterpreterState {
    Idle;
    Hinting;
    Executing;
}
