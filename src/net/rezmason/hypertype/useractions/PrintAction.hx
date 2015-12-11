package net.rezmason.hypertype.useractions;

import lime.Assets.*;
import net.rezmason.hypertype.console.UserAction;
import net.rezmason.hypertype.console.ConsoleTypes;
import net.rezmason.hypertype.console.ConsoleUtils.*;

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
