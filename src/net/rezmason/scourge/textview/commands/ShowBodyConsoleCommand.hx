package net.rezmason.scourge.textview.commands;

import openfl.Assets.*;
import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;

class ShowBodyConsoleCommand extends ConsoleCommand {

    var hasBody:String->Bool;
    var showBody:String->Void;

    public function new(hasBody:String->Bool, showBody:String->Void):Void {
        super();
        name = 'show';
        this.hasBody = hasBody;
        this.showBody = showBody;
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        var bodyName:String = args.tail;
        var message:String = null;
        if (hasBody(bodyName)) {
            message = 'Showing $bodyName';
            showBody(bodyName);
        } else {
            message = styleError('Body "$bodyName" not found.');
        }

        outputSignal.dispatch(message, true);
    }
}
