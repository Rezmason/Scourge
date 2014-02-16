package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Zig;

class ConsoleCommand {

    public var name(default, null):String;
    public var flags(default, null):Array<String>;
    public var keys(default, null):Map<String, String>;

    public var outputSignal:Zig<String->Bool->Void>;
    public var hintSignal:Zig<String->Array<ConsoleToken>->Void>;

    public function new():Void {
        outputSignal = new Zig();
        hintSignal = new Zig();

        name = "burp";

        flags = ["one", "two", "ad"];
        keys = ['a'=>'apple', 'b'=>'ball', 'ac'=>null];

        // flags = [];
        // keys = new Map();
    }

    public function hint(args:ConsoleCommandArgs):Void {
        hintSignal.dispatch('WHOOP!', [
            {text:'ONE', type:Value},
            {text:'TWO', type:Value},
            {text:'THREE', type:Value},
        ]);
    }

    public function execute(args:ConsoleCommandArgs):Void {
        outputSignal.dispatch('OUTPUT 1! ${args.keyValuePairs["a"]}', false);
        outputSignal.dispatch('OUTPUT 2! ${args.keyValuePairs["b"]}', true);
    }

    public function hintRollOver(args:ConsoleCommandArgs, hint:ConsoleToken):Void {
        trace(hint.text);
    }

    public function hintRollOut():Void {
        trace('derp');
    }
}
