package net.rezmason.scourge.textview.commands;

import haxe.Timer;

import openfl.Assets.*;
import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;

class QuitConsoleCommand extends ConsoleCommand {

    public function new():Void {
        super();
        name = 'quit';
    }

    override public function execute(args:ConsoleCommandArgs):Void Sys.exit(0);
}
