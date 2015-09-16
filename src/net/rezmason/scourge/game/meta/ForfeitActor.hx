package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.body.BodyAspect;

class ForfeitActor extends Actor<Dynamic> {

    @player(BodyAspect.HEAD, true) var head_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _chooseMove(_):Void {
        getPlayer(state.global[currentPlayer_])[head_] = NULL;
        signalChange();
    }
}

