package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.praxis.aspect.WinAspect;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;

class ForfeitRule extends BaseRule<Void> {

    @player(BodyAspect.HEAD) var head_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _chooseMove(choice:Int):Void {
        getPlayer(state.global[currentPlayer_])[head_] = NULL;
        signalChange();
    }
}

