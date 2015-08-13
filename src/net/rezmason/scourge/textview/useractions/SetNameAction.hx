package net.rezmason.scourge.textview.useractions;

import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.Interpreter;

class SetNameAction extends UserAction {

    var interpreter:Interpreter;

    public function new(interpreter:Interpreter):Void {
        super();
        name = 'setName';
        this.interpreter = interpreter;
    }

    override public function execute(args:UserActionArgs):Void {
        var name:String = args.tail;
        if (name == null) name = "SOME DWEEB";
        var color = Std.random(0xFF) << 16 | Std.random(0xFF) << 8 | Std.random(0xFF);
        interpreter.setPrompt(name, color);
        outputSignal.dispatch(null, true);
    }
}
