package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

class ResetFreshnessRule extends Rule {

    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    
    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
        for (node in eachNode()) node[freshness_] = Aspect.NULL;
        state.aspects[maxFreshness_] = 0;
        signalEvent();
    }
}

