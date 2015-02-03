package net.rezmason.scourge.model.meta;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;

using Lambda;
using net.rezmason.ropes.AspectUtils;

using net.rezmason.utils.Pointers;

typedef ReplenishableParams = {
    var prop:AspectProperty;
    var amount:Int;
    var period:Int;
    var maxAmount:Int;
    @:optional var replenishableID:Int;
}

typedef ReplenishParams = {
    var globalProperties:Array<ReplenishableParams>;
    var playerProperties:Array<ReplenishableParams>;
    var nodeProperties:Array<ReplenishableParams>;
}

class ReplenishRule extends RopesRule<ReplenishParams> {

    // state, extra for each replenishable
    @extra(ReplenishableAspect.REP_NEXT) var repNext_;
    @extra(ReplenishableAspect.REP_PREV) var repPrev_;

    @extra(ReplenishableAspect.REP_PROP_LOOKUP) var repPropLookup_;
    @extra(ReplenishableAspect.REP_STEP) var repStep_;

    @global(ReplenishableAspect.STATE_REP_FIRST) var stateRepFirst_;
    @global(ReplenishableAspect.PLAYER_REP_FIRST) var playerRepFirst_;
    @global(ReplenishableAspect.NODE_REP_FIRST) var nodeRepFirst_;

    override public function _init():Void {
        for (rProp in params.globalProperties ) addGlobalAspectRequirement(rProp.prop);
        for (rProp in params.playerProperties ) addPlayerAspectRequirement(rProp.prop);
        for (rProp in params.nodeProperties   ) addNodeAspectRequirement  (rProp.prop);
    }

    override private function _prime():Void {

        // As a meta-rule, ReplenishRule has a relatively complex init function.

        var stateReps:Array<AspectSet> = [];
        var playerReps:Array<AspectSet> = [];
        var nodeReps:Array<AspectSet> = [];

        // Create the replenishables
        for (repCfg in params.globalProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.globalAspectLookup);
            repCfg.replenishableID = replenishable[ident_];
            stateReps.push(replenishable);
        }

        for (repCfg in params.playerProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.playerAspectLookup);
            repCfg.replenishableID = replenishable[ident_];
            playerReps.push(replenishable);
        }

        for (repCfg in params.nodeProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.nodeAspectLookup);
            repCfg.replenishableID = replenishable[ident_];
            nodeReps.push(replenishable);
        }

        // List the replenishables

        if (stateReps.length > 0) {
            stateReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[stateRepFirst_] = stateReps[0][ident_];
        } else {
            state.global[stateRepFirst_] = NULL;
        }

        if (playerReps.length > 0) {
            playerReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[playerRepFirst_] = playerReps[0][ident_];
        } else {
            state.global[playerRepFirst_] = NULL;
        }

        if (nodeReps.length > 0) {
            nodeReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[nodeRepFirst_] = nodeReps[0][ident_];
        } else {
            state.global[nodeRepFirst_] = NULL;
        }
    }

    override private function _chooseMove(choice:Int):Void {
        updateReps(params.globalProperties, [state.global]);
        updateReps(params.playerProperties, state.players);
        updateReps(params.nodeProperties, state.nodes);
        signalChange();
    }

    private function makeReplenishable(repCfg:ReplenishableParams, lookup:AspectLookup):AspectSet {

        // A replenishable is really just an accumulator that performs an action
        // on a value stored in a particular aspect set, at a specific index

        // We represent replenishables as extras
        var rep:AspectSet = addExtra();
        rep[repPropLookup_] = lookup[repCfg.prop.id].toInt();
        return rep;
    }

    private function updateReps(repCfgs:Array<ReplenishableParams>, aspectSets:Array<AspectSet>):Void {
        // Each replenishable gets its iterator incremented
        for (repCfg in repCfgs) {
            var replenishable:AspectSet = getExtra(repCfg.replenishableID);
            var step:Int = replenishable[repStep_];
            step++;
            if (step == repCfg.period) {
                // Time for action! Resolve the pointer and update values at that location
                step = 0;
                var ptr:AspectPtr = AspectPtr.intToPointer(replenishable[repPropLookup_], state.key);
                for (aspectSet in aspectSets) {
                    var value:Int = aspectSet[ptr];
                    value += repCfg.amount;
                    if (value > repCfg.maxAmount) value = repCfg.maxAmount;
                    aspectSet[ptr] = value;
                }
            }
            replenishable[repStep_] = step;
        }
    }
}

