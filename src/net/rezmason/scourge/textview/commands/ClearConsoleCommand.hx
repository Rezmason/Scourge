package net.rezmason.scourge.textview.commands;

import openfl.Assets.*;
import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.scourge.textview.console.ConsoleUIMediator;

using net.rezmason.utils.ArrayUtils;

class ClearConsoleCommand extends ConsoleCommand {

    var console:ConsoleUIMediator;

    public function new(console:ConsoleUIMediator):Void {
        super();
        name = 'clear';
        this.console = console;
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        console.clearText();
        outputSignal.dispatch(null, true);
    }
}
