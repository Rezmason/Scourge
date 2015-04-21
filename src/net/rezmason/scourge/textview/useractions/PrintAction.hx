package net.rezmason.scourge.textview.useractions;

import openfl.Assets.*;
import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;

using net.rezmason.utils.ArrayUtils;

class PrintAction extends UserAction {

    public function new():Void {
        super();
        name = 'print';
    }

    override public function execute(args:UserActionArgs):Void {
        if (!exists(args.tail)) outputSignal.dispatch(styleError('Asset "${args.tail}" not found.'), true);
        else outputSignal.dispatch(getText(args.tail), true);
    }
}
