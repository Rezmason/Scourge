package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.pointers.Pointers;

class ReplenishRule extends BaseRule<ReplenishParams> {

    @extra(ReplenishableAspect.REP_NEXT, true) var repNext_;
    @extra(ReplenishableAspect.REP_PREV, true) var repPrev_;
    @extra(ReplenishableAspect.REP_STEP, true) var repStep_;

    @global(ReplenishableAspect.GLOBAL_REP_FIRST, true) var globalRepFirst_;
    @global(ReplenishableAspect.PLAYER_REP_FIRST, true) var playerRepFirst_;
    @global(ReplenishableAspect.CARD_REP_FIRST, true) var cardRepFirst_;
    @global(ReplenishableAspect.NODE_REP_FIRST, true) var spaceRepFirst_;

    private var globalProperties:Array<ReplenishableProperty>;
    private var playerProperties:Array<ReplenishableProperty>;
    private var cardProperties:Array<ReplenishableProperty>;
    private var spaceProperties:Array<ReplenishableProperty>;
    
    override public function _init():Void {

        globalProperties = [ for (key in params.globalProperties.keys().a2z() ) params.globalProperties[key] ];
        playerProperties = [ for (key in params.playerProperties.keys().a2z() ) params.playerProperties[key] ];
        cardProperties   = [ for (key in params.cardProperties  .keys().a2z() ) params.cardProperties  [key] ];
        spaceProperties  = [ for (key in params.spaceProperties .keys().a2z() ) params.spaceProperties [key] ];

        for (rProp in globalProperties ) addGlobalAspectRequirement(rProp.prop);
        for (rProp in playerProperties ) addPlayerAspectRequirement(rProp.prop);
        for (rProp in cardProperties   ) addCardAspectRequirement  (rProp.prop);
        for (rProp in spaceProperties  ) addSpaceAspectRequirement (rProp.prop);
    }

    override private function _prime():Void {

        // As a meta-rule, ReplenishRule has a relatively complex init function.

        var globalReps:Array<AspectSet> = [];
        var playerReps:Array<AspectSet> = [];
        var cardReps:Array<AspectSet> = [];        
        var spaceReps:Array<AspectSet> = [];

        // Create the replenishables
        for (repProp in globalProperties) {
            var replenishable:AspectSet = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.globalAspectLookup[repProp.prop.id];
            globalReps.push(replenishable);
        }

        for (repProp in playerProperties) {
            var replenishable:AspectSet = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.playerAspectLookup[repProp.prop.id];
            playerReps.push(replenishable);
        }

        for (repProp in cardProperties) {
            var replenishable:AspectSet = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.cardAspectLookup[repProp.prop.id];
            cardReps.push(replenishable);
        }

        for (repProp in spaceProperties) {
            var replenishable:AspectSet = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.spaceAspectLookup[repProp.prop.id];
            spaceReps.push(replenishable);
        }

        // List the replenishables

        if (globalReps.length > 0) {
            globalReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[globalRepFirst_] = getID(globalReps[0]);
        } else {
            state.global[globalRepFirst_] = NULL;
        }

        if (playerReps.length > 0) {
            playerReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[playerRepFirst_] = getID(playerReps[0]);
        } else {
            state.global[playerRepFirst_] = NULL;
        }

        if (cardReps.length > 0) {
            cardReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[cardRepFirst_] = getID(cardReps[0]);
        } else {
            state.global[cardRepFirst_] = NULL;
        }

        if (spaceReps.length > 0) {
            spaceReps.chainByAspect(ident_, repNext_, repPrev_);
            state.global[spaceRepFirst_] = getID(spaceReps[0]);
        } else {
            state.global[spaceRepFirst_] = NULL;
        }
    }

    override private function _chooseMove(choice:Int):Void {
        updateReps(globalProperties, [state.global]);
        updateReps(playerProperties, state.players);
        updateReps(cardProperties, state.cards);
        updateReps(spaceProperties, state.spaces);
        signalChange();
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
                var ptr:AspectWritePtr = repProp.replenishablePtr;
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

