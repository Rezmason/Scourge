package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
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
    var buildCfg:BuildConfig;
    var stateProperties:Array<ReplenishableConfig>;
    var playerProperties:Array<ReplenishableConfig>;
    var nodeProperties:Array<ReplenishableConfig>;
}

class ReplenishRule extends Rule {

    // state, extra for each replenishable
    @extra(ReplenishableAspect.REP_ID) var repID_;
    @extra(ReplenishableAspect.REP_NEXT) var repNext_;
    @extra(ReplenishableAspect.REP_PREV) var repPrev_;

    @extra(ReplenishableAspect.REP_PROP_LOOKUP) var repPropLookup_;
    @extra(ReplenishableAspect.REP_STEP) var repStep_;

    @state(ReplenishableAspect.STATE_REP_FIRST) var stateRepFirst_;
    @state(ReplenishableAspect.PLAYER_REP_FIRST) var playerRepFirst_;
    @state(ReplenishableAspect.NODE_REP_FIRST) var nodeRepFirst_;

    var cfg:ReplenishConfig;

    public function new(cfg:ReplenishConfig):Void {
        super();
        this.cfg = cfg;

        for (rProp in cfg.stateProperties ) addStateAspectRequirement (rProp.prop);
        for (rProp in cfg.playerProperties) addPlayerAspectRequirement(rProp.prop);
        for (rProp in cfg.nodeProperties  ) addNodeAspectRequirement  (rProp.prop);

        moves.push({id:0});
    }

    override private function _prime():Void {

        // As a meta-rule, ReplenishRule has a relatively complex init function.

        var stateReps:Array<AspectSet> = [];
        var playerReps:Array<AspectSet> = [];
        var nodeReps:Array<AspectSet> = [];

        // Create the replenishables
        for (repCfg in cfg.stateProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.stateAspectLookup);
            repCfg.replenishableID = replenishable[repID_];
            stateReps.push(replenishable);
        }

        for (repCfg in cfg.playerProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.playerAspectLookup);
            repCfg.replenishableID = replenishable[repID_];
            playerReps.push(replenishable);
        }

        for (repCfg in cfg.nodeProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.nodeAspectLookup);
            repCfg.replenishableID = replenishable[repID_];
            nodeReps.push(replenishable);
        }

        // List the replenishables

        if (stateReps.length > 0) {
            stateReps.chainByAspect(repID_, repNext_, repPrev_);
            state.aspects[stateRepFirst_] = stateReps[0][repID_];
        } else {
            state.aspects[stateRepFirst_] = Aspect.NULL;
        }

        if (playerReps.length > 0) {
            playerReps.chainByAspect(repID_, repNext_, repPrev_);
            state.aspects[playerRepFirst_] = playerReps[0][repID_];
        } else {
            state.aspects[playerRepFirst_] = Aspect.NULL;
        }

        if (nodeReps.length > 0) {
            nodeReps.chainByAspect(repID_, repNext_, repPrev_);
            state.aspects[nodeRepFirst_] = nodeReps[0][repID_];
        } else {
            state.aspects[nodeRepFirst_] = Aspect.NULL;
        }
    }

    override private function _chooseMove(choice:Int):Void {
        updateReps(cfg.stateProperties, [state.aspects]);
        updateReps(cfg.playerProperties, state.players);
        updateReps(cfg.nodeProperties, state.nodes);
        signalEvent();
    }

    private function makeReplenishable(repCfg:ReplenishableConfig, lookup:AspectLookup):AspectSet {

        // A replenishable is really just an accumulator that performs an action
        // on a value stored in a particular aspect set, at a specific index

        // We represent replenishables as extras
        var rep:AspectSet = buildExtra();

        rep[repPropLookup_] = lookup[repCfg.prop.id].toInt();
        rep[repID_] = numExtras();

        state.extras.push(rep);
        cfg.buildCfg.historyState.extras.push(buildHistExtra(cfg.buildCfg.history));

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

