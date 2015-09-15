package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Actor;

class ResetFreshnessActor extends Actor<Dynamic> {

    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;
    
    override private function _chooseMove(_):Void {
        for (space in eachSpace()) space[freshness_] = NULL;
        state.global[maxFreshness_] = 0;
        signalChange();
    }
}

