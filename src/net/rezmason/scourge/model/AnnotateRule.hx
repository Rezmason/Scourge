package net.rezmason.scourge.model;

import net.rezmason.ropes.Rule;
using net.rezmason.utils.Pointers;

class AnnotateRule extends Rule {
    var func:Void->Void;

    public function new(func:Void->Void):Void { super(); this.func = func; options.push({optionID:0}); }

    override public function _chooseOption(choice:Int):Void {
        state.key.lock();
        func();
        state.key.unlock();
    }
}
