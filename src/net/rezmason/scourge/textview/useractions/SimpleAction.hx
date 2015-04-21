package net.rezmason.scourge.textview.useractions;

import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Zig;

class SimpleAction extends UserAction {

    var func:UserActionArgs->Zig<String->Bool->Void>->Void;

    public function new(name, func):Void {
        super();
        this.name = name;
        this.func = func;
    }

    override public function execute(args):Void func(args, outputSignal);
}
