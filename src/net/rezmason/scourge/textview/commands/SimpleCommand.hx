package net.rezmason.scourge.textview.commands;

import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Zig;

class SimpleCommand extends ConsoleCommand {

    var func:ConsoleCommandArgs->Zig<String->Bool->Void>->Void;

    public function new(name, func):Void {
        super();
        this.name = name;
        this.func = func;
    }

    override public function execute(args):Void func(args, outputSignal);
}
