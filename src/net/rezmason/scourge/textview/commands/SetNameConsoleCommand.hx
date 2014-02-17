package net.rezmason.scourge.textview.commands;

import massive.munit.TestRunner;

import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.Interpreter;

class SetNameConsoleCommand extends ConsoleCommand {

    var interpreter:Interpreter;

    public function new(interpreter:Interpreter):Void {
        super();
        name = 'setName';
        this.interpreter = interpreter;
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        var name:String = args.tail;
        if (name == null) name = "SOME DWEEB";
        var color = Std.random(0xFF) << 16 | Std.random(0xFF) << 8 | Std.random(0xFF);
        interpreter.setPrompt(name, color);
        outputSignal.dispatch(null, true);
    }
}
