package net.rezmason.scourge.textview.commands;

import openfl.Assets.*;
import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.scourge.DisplaySystem;

class ShowBodyConsoleCommand extends ConsoleCommand {

    var displaySystem:DisplaySystem;

    public function new(displaySystem:DisplaySystem):Void {
        super();
        name = 'show';
        this.displaySystem = displaySystem;
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        var bodyName:String = args.tail;
        var message:String = null;
        if (displaySystem.hasBody(bodyName)) {
            message = 'Showing $bodyName';
            displaySystem.showBody(bodyName, 'main');
        } else {
            message = styleError('Body "$bodyName" not found.');
        }

        outputSignal.dispatch(message, true);
    }
}
