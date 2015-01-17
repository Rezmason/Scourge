package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.RopesRule;
// import net.rezmason.scourge.model.aspects.BodyAspect;
// using net.rezmason.scourge.model.BoardUtils;

class DebugRule extends RopesRule<Void> {
    // @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    override private function _chooseMove(choice:Int):Void {
        // trace(state.spitBoard(plan));
    }
}

