package net.rezmason.hypertype.useractions;

import net.rezmason.hypertype.console.UserAction;
import net.rezmason.hypertype.console.ConsoleTypes;
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
