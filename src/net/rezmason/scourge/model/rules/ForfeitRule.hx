package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
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
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int = 0):Void {
        super.chooseOption(choice);

        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var player:AspectSet = state.players[currentPlayer];
        var bodyNode:BoardNode = state.nodes[player.at(bodyFirst_)];

        // Clear the player's head and body

        for (node in bodyNode.boardListToArray(state.nodes, bodyNext_)) killCell(node, maxFreshness);
        player.mod(bodyFirst_, Aspect.NULL);
        player.mod(head_, Aspect.NULL);

        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me.at(isFilled_) == Aspect.FALSE) return false;
        return me.at(occupier_) == you.at(occupier_);
    }

    function killCell(node:BoardNode, maxFreshness:Int):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);
        node.value.mod(freshness_, maxFreshness);

        node.removeNode(state.nodes, bodyNext_, bodyPrev_);
    }
}

