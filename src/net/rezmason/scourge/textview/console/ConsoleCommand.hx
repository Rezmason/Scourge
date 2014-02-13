package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Zig;

class ConsoleCommand {

    public var name(default, null):String;
    public var flags(default, null):Array<String>;
    public var keys(default, null):Map<String, String>;

    public var errorSignal:Zig<String->Void>;
    public var outputSignal:Zig<String->Bool->Void>;

    public function new():Void {
        name = "burp";
        flags = ["one", "two"];
        keys = ['a'=>'apple', 'b'=>'ball'];
    }

    public function execute(args:ConsoleCommandArgs):Void {

    }
}
