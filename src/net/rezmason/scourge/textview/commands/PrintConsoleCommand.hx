package net.rezmason.scourge.textview.commands;

import openfl.Assets.*;
import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;

using net.rezmason.utils.ArrayUtils;

class PrintConsoleCommand extends ConsoleCommand {

    public function new():Void {
        super();
        name = 'print';
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        if (!exists(args.tail)) outputSignal.dispatch(styleError('Asset ${args.tail} not found.'), true);
        else outputSignal.dispatch(getText(args.tail), true);
    }
}
