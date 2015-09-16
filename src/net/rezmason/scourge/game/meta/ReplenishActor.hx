package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.Actor;

class ReplenishActor extends Actor<ReplenishParams> {

    @extra(ReplenishableAspect.REP_STEP, true) var repStep_;

    override private function _chooseMove(_):Void {
        updateReps(params.globalProperties, [state.global]);
        updateReps(params.playerProperties, state.players);
        updateReps(params.cardProperties, state.cards);
        updateReps(params.spaceProperties, state.spaces);
        signalChange();
    }

    private function updateReps<T>(repProps:Map<String, ReplenishableProperty<T>>, aspectPointables:Array<AspectPointable<T>>):Void {
        // Each replenishable gets its iterator incremented
        for (repProp in repProps) {
            var replenishable = getExtra(repProp.replenishableID);
            var step = replenishable[repStep_];
            step++;
            if (step == repProp.period) {
                // Time for action! Resolve the pointer and update values at that location
                step = 0;
                var ptr = repProp.replenishablePtr;
                for (aspectPointable in aspectPointables) {
                    var value = aspectPointable[ptr];
                    value += repProp.amount;
                    if (value > repProp.maxAmount) value = repProp.maxAmount;
                    aspectPointable[ptr] = value;
                }
            }
            replenishable[repStep_] = step;
        }
    }
}

