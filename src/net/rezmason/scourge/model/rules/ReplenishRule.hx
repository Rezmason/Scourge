package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.ReplenishableAspect;

using Lambda;
using net.rezmason.ropes.AspectUtils;

using net.rezmason.utils.Pointers;

typedef ReplenishableConfig = {
    var prop:AspectProperty;
    var amount:Int;
    var period:Int;
    var maxAmount:Int;
    @:optional var replenishableID:Int;
}

typedef ReplenishConfig = {
    var globalProperties:Array<ReplenishableConfig>;
    var playerProperties:Array<ReplenishableConfig>;
    var nodeProperties:Array<ReplenishableConfig>;
}

class ReplenishRule extends RopesRule<ReplenishConfig> {

    // state, extra for each replenishable
    @extra(ReplenishableAspect.REP_NEXT) var repNext_;
    @extra(ReplenishableAspect.REP_PREV) var repPrev_;

    @extra(ReplenishableAspect.REP_PROP_LOOKUP) var repPropLookup_;
    @extra(ReplenishableAspect.REP_STEP) var repStep_;

    @global(ReplenishableAspect.STATE_REP_FIRST) var stateRepFirst_;
    @global(ReplenishableAspect.PLAYER_REP_FIRST) var playerRepFirst_;
    @global(ReplenishableAspect.NODE_REP_FIRST) var nodeRepFirst_;

    override public function _init():Void {
        for (rProp in config.globalProperties ) addGlobalAspectRequirement(rProp.prop);
        for (rProp in config.playerProperties ) addPlayerAspectRequirement(rProp.prop);
        for (rProp in config.nodeProperties   ) addNodeAspectRequirement  (rProp.prop);
    }

    override private function _prime():Void {

        // As a meta-rule, ReplenishRule has a relatively complex init function.

        var stateReps:Array<AspectSet> = [];
        var playerReps:Array<AspectSet> = [];
        var nodeReps:Array<AspectSet> = [];

        // Create the replenishables
        for (repCfg in config.globalProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.globalAspectLookup);
            repCfg.replenishableID = replenishable[ident_];
            stateReps.push(replenishable);
        }

        for (repCfg in config.playerProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.playerAspectLookup);
            repCfg.replenishableID = replenishable[ident_];
            playerReps.push(replenishable);
        }

        for (repCfg in config.nodeProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.nodeAspectLookup);
            repCfg.replenishableID = replenishable[ident_];
            nodeReps.push(replenishable);
        }

        // List the replenishables

        if (stateReps.length > 0) {
            stateReps.chainByAspect(ident_, repNext_, repPrev_);
            state.globals[stateRepFirst_] = stateReps[0][ident_];
        } else {
            state.globals[stateRepFirst_] = Aspect.NULL;
        }

        if (playerReps.length > 0) {
            playerReps.chainByAspect(ident_, repNext_, repPrev_);
            state.globals[playerRepFirst_] = playerReps[0][ident_];
        } else {
            state.globals[playerRepFirst_] = Aspect.NULL;
        }

        if (nodeReps.length > 0) {
            nodeReps.chainByAspect(ident_, repNext_, repPrev_);
            state.globals[nodeRepFirst_] = nodeReps[0][ident_];
        } else {
            state.globals[nodeRepFirst_] = Aspect.NULL;
        }
    }

    override private function _chooseMove(choice:Int):Void {
        updateReps(config.globalProperties, [state.globals]);
        updateReps(config.playerProperties, state.players);
        updateReps(config.nodeProperties, state.nodes);
        onSignal();
    }

    private function makeReplenishable(repCfg:ReplenishableConfig, lookup:AspectLookup):AspectSet {

        // A replenishable is really just an accumulator that performs an action
        // on a value stored in a particular aspect set, at a specific index

        // We represent replenishables as extras
        var rep:AspectSet = addExtra();
        rep[repPropLookup_] = lookup[repCfg.prop.id].toInt();
        return rep;
    }

    private function updateReps(repCfgs:Array<ReplenishableConfig>, aspectSets:Array<AspectSet>):Void {
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

