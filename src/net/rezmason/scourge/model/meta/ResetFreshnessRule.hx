package net.rezmason.scourge.model.meta;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.rule.BaseRule;

class ResetFreshnessRule extends BaseRule<Void> {

    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    
    override private function _chooseMove(choice:Int):Void {
        for (node in eachNode()) node[freshness_] = NULL;
        state.global[maxFreshness_] = 0;
        signalChange();
    }
}

