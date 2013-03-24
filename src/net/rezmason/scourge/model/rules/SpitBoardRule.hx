package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Rule;

using net.rezmason.scourge.model.BoardUtils;

class SpitBoardRule extends Rule {

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
        trace(state.spitBoard(plan));
    }
}

