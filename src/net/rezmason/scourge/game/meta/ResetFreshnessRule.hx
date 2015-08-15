package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.BaseRule;

class ResetFreshnessRule extends BaseRule<Dynamic> {

    @space(FreshnessAspect.FRESHNESS) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    
    override private function _chooseMove(choice:Int):Void {
        for (space in eachSpace()) space[freshness_] = NULL;
        state.global[maxFreshness_] = 0;
        signalChange();
    }
}

