package net.rezmason.scourge.model.meta;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;

using Lambda;
using net.rezmason.utils.Alphabetizer;
using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.Pointers;

class ReplenishRule extends RopesRule<ReplenishParams> {

    // state, extra for each replenishable
    @extra(ReplenishableAspect.REP_NEXT) var repNext_;
    @extra(ReplenishableAspect.REP_PREV) var repPrev_;

    @extra(ReplenishableAspect.REP_PROP_LOOKUP) var repPropLookup_;
    @extra(ReplenishableAspect.REP_STEP) var repStep_;

    @global(ReplenishableAspect.STATE_REP_FIRST) var stateRepFirst_;
    @global(ReplenishableAspect.PLAYER_REP_FIRST) var playerRepFirst_;
    @global(ReplenishableAspect.NODE_REP_FIRST) var nodeRepFirst_;

    private var globalProperties:Array<ReplenishableProperty>;
    private var playerProperties:Array<ReplenishableProperty>;
    private var nodeProperties:Array<ReplenishableProperty>;
    
    override public function _init():Void {

        globalProperties = [ for (key in params.globalProperties.keys().a2z() ) params.globalProperties[key] ];
        playerProperties = [ for (key in params.playerProperties.keys().a2z() ) params.playerProperties[key] ];
        nodeProperties   = [ for (key in params.nodeProperties  .keys().a2z() ) params.nodeProperties  [key] ];

        for (rProp in globalProperties ) addGlobalAspectRequirement(rProp.prop);
        for (rProp in playerProperties ) addPlayerAspectRequirement(rProp.prop);
        for (rProp in nodeProperties   ) addNodeAspectRequirement  (rProp.prop);
    }

    override private function _prime():Void {

        // As a meta-rule, ReplenishRule has a relatively complex init function.

        var stateReps:Array<AspectSet> = [];
        var playerReps:Array<AspectSet> = [];
        var nodeReps:Array<AspectSet> = [];

        // Create the replenishables
        for (repProp in globalProperties) {
            var replenishable:AspectSet = makeReplenishable(repProp, plan.globalAspectLookup);
            repProp.replenishableID = replenishable[ident_];
            stateReps.push(replenishable);
        }

        for (repProp in playerProperties) {
            var replenishable:AspectSet = makeReplenishable(repProp, plan.playerAspectLookup);
            repProp.replenishableID = replenishable[ident_];
            playerReps.push(replenishable);
        }

        for (repProp in nodeProperties) {
            var replenishable:AspectSet = makeReplenishable(repProp, plan.nodeAspectLookup);
            repProp.replenishableID = replenishable[ident_];
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
        updateReps(globalProperties, [state.global]);
        updateReps(playerProperties, state.players);
        updateReps(nodeProperties, state.nodes);
        signalChange();
    }

    private function makeReplenishable(repProp:ReplenishableProperty, lookup:AspectLookup):AspectSet {

        // A replenishable is really just an accumulator that performs an action
        // on a value stored in a particular aspect set, at a specific index

        // We represent replenishables as extras
        var rep:AspectSet = addExtra();
        rep[repPropLookup_] = lookup[repProp.prop.id].toInt();
        return rep;
    }

    private function updateReps(repProps:Array<ReplenishableProperty>, aspectSets:Array<AspectSet>):Void {
        // Each replenishable gets its iterator incremented
        for (repProp in repProps) {
            var replenishable:AspectSet = getExtra(repProp.replenishableID);
            var step:Int = replenishable[repStep_];
            step++;
            if (step == repProp.period) {
                // Time for action! Resolve the pointer and update values at that location
                step = 0;
                var ptr:AspectPtr = AspectPtr.intToPointer(replenishable[repPropLookup_], state.key);
                for (aspectSet in aspectSets) {
                    var value:Int = aspectSet[ptr];
                    value += repProp.amount;
                    if (value > repProp.maxAmount) value = repProp.maxAmount;
                    aspectSet[ptr] = value;
                }
            }
            replenishable[repStep_] = step;
        }
    }
}

