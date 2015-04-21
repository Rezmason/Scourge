package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Zig;

class UserAction {

    public var name(default, null):String;
    public var flags(default, null):Array<String>;
    public var keys(default, null):Map<String, String>;

    public var outputSignal(default, null):Zig<String->Bool->Void>;
    public var hintSignal(default, null):Zig<String->Array<ConsoleToken>->Void>;

    public function new():Void {
        outputSignal = new Zig();
        hintSignal = new Zig();
        name = '';
        flags = [];
        keys = new Map();
    }

    public function hint(args:UserActionArgs):Void hintSignal.dispatch(null, null);
    public function execute(args:UserActionArgs):Void outputSignal.dispatch(null, true);
    public function hintRollOver(args:UserActionArgs, hint:ConsoleToken):Void { }
    public function hintRollOut():Void { }
}
