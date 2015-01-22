package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

class ResetFreshnessRule extends RopesRule<Void> {

    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    
    override private function _chooseMove(choice:Int):Void {
        for (node in eachNode()) node[freshness_] = NULL;
        state.globals[maxFreshness_] = 0;
        signalChange();
    }
}

