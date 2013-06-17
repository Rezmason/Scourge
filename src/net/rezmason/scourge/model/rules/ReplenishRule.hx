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

        for (rProp in cfg.stateProperties) stateAspectRequirements.push(rProp.prop);
        for (rProp in cfg.playerProperties) playerAspectRequirements.push(rProp.prop);
        for (rProp in cfg.nodeProperties) nodeAspectRequirements.push(rProp.prop);

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
            repCfg.replenishableID = replenishable.at(repID_);
            stateReps.push(replenishable);
        }

        for (repCfg in cfg.playerProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.playerAspectLookup);
            repCfg.replenishableID = replenishable.at(repID_);
            playerReps.push(replenishable);
        }

        for (repCfg in cfg.nodeProperties) {
            var replenishable:AspectSet = makeReplenishable(repCfg, plan.nodeAspectLookup);
            repCfg.replenishableID = replenishable.at(repID_);
            nodeReps.push(replenishable);
        }

        // List the replenishables

        if (stateReps.length > 0) {
            stateReps.chainByAspect(repID_, repNext_, repPrev_);
            state.aspects.mod(stateRepFirst_, stateReps[0].at(repID_));
        } else {
            state.aspects.mod(stateRepFirst_, Aspect.NULL);
        }

        if (playerReps.length > 0) {
            playerReps.chainByAspect(repID_, repNext_, repPrev_);
            state.aspects.mod(playerRepFirst_, playerReps[0].at(repID_));
        } else {
            state.aspects.mod(playerRepFirst_, Aspect.NULL);
        }

        if (nodeReps.length > 0) {
            nodeReps.chainByAspect(repID_, repNext_, repPrev_);
            state.aspects.mod(nodeRepFirst_, nodeReps[0].at(repID_));
        } else {
            state.aspects.mod(nodeRepFirst_, Aspect.NULL);
        }
    }

    override private function _chooseMove(choice:Int):Void {

        updateReps(cfg.stateProperties, updateState);
        updateReps(cfg.playerProperties, updatePlayers);
        updateReps(cfg.nodeProperties, updateNodes);
    }

    private function makeReplenishable(repCfg:ReplenishableConfig, lookup:AspectLookup):AspectSet {

        // A replenishable is really just an accumulator that performs an action
        // on a value stored in a particular aspect set, at a specific index

        // We represent replenishables as extras
        var rep:AspectSet = buildExtra();
        rep.mod(repPropLookup_, lookup[repCfg.prop.id].toInt());
        rep.mod(repID_, numExtras());

        state.extras.push(rep);
        cfg.buildCfg.historyState.extras.push(buildHistExtra(cfg.buildCfg.history));

        return rep;
    }

    private function updateReps(repCfgs:Array<ReplenishableConfig>, updateFunc:ReplenishableConfig->AspectPtr->Void):Void {
        // Each replenishable gets its iterator incremented
        for (repCfg in repCfgs) {
            var replenishable:AspectSet = getExtra(repCfg.replenishableID);
            var step:Int = replenishable.at(repStep_);
            step++;
            if (step == repCfg.period) {
                // Time for action! Resolve the pointer and update values at that location
                step = 0;
                var ptr:AspectPtr = AspectPtr.intToPointer(replenishable.at(repPropLookup_), state.key);
                updateFunc(repCfg, ptr); // TODO: Do this with fewer function calls (and iterations)
            }
            replenishable.mod(repStep_, step);
        }
    }

    // Only one aspect set to update– the state's.
    private function updateState(repCfg:ReplenishableConfig, ptr:AspectPtr):Void {
        var value:Int = state.aspects.at(ptr);
        value += repCfg.amount;
        if (value > repCfg.maxAmount) value = repCfg.maxAmount;
        state.aspects.mod(ptr, value);
    }

    // Update each player's aspect set
    private function updatePlayers(repCfg:ReplenishableConfig, ptr:AspectPtr):Void {
        for (player in eachPlayer()) {
            var value:Int = player.at(ptr);
            value += repCfg.amount;
            if (value > repCfg.maxAmount) value = repCfg.maxAmount;
            player.mod(ptr, value);
        }
    }

    // Update each node's aspect set
    private function updateNodes(repCfg:ReplenishableConfig, ptr:AspectPtr):Void {
        for (node in eachNode()) {
            var value:Int = node.value.at(ptr);
            value += repCfg.amount;
            if (value > repCfg.maxAmount) value = repCfg.maxAmount;
            node.value.mod(ptr, value);
        }
    }
}

