package net.rezmason.hypertype.useractions;

import net.rezmason.math.Vec3;
import net.rezmason.hypertype.console.UserAction;
import net.rezmason.hypertype.console.ConsoleTypes;
import net.rezmason.hypertype.console.Interpreter;

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
        var color = Vec3.fromHex(Std.random(0xFFFFFF)) * 0.5 + 0.5;
        interpreter.setPrompt(name, color);
        outputSignal.dispatch(null, true);
    }
}
