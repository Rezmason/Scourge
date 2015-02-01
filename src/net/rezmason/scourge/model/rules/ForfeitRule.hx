package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class ForfeitRule extends RopesRule<Void> {

    @player(BodyAspect.HEAD) var head_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _chooseMove(choice:Int):Void {
        getPlayer(state.global[currentPlayer_])[head_] = NULL;
        signalChange();
    }
}

