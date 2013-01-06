package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Rule;

using net.rezmason.scourge.model.BoardUtils;

class SpitBoardRule extends Rule {

    public function new():Void {
        super();
        options.push({optionID:0});
    }

    override private function _chooseOption(choice:Int):Void {
        trace(state.spitBoard(plan));
    }
}

