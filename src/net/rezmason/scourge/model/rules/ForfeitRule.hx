package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class ForfeitRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var maxFreshness:Int = state.aspects[maxFreshness_] + 1;

        var currentPlayer:Int = state.aspects[currentPlayer_];
        var player:AspectSet = getPlayer(currentPlayer);
        var bodyNode:BoardNode = getNode(player[bodyFirst_]);

        // Clear the player's head and body

        for (node in bodyNode.boardListToArray(state.nodes, bodyNext_)) killCell(node, maxFreshness);
        player[bodyFirst_] = Aspect.NULL;
        player[head_] = Aspect.NULL;

        state.aspects[maxFreshness_] = maxFreshness;
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me[isFilled_] == Aspect.FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function killCell(node:BoardNode, maxFreshness:Int):Void {
        node.value[isFilled_] = Aspect.FALSE;
        node.value[occupier_] = Aspect.NULL;
        node.value[freshness_] = maxFreshness;

        node.removeNode(state.nodes, bodyNext_, bodyPrev_);
    }
}

