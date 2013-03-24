package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

//using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessPlayerRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(IdentityAspect.PLAYER_ID) var playerID_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        // Check each player to see if their heads are no longer theirs

        for (player in eachPlayer()) {
            var playerID:Int = player.at(playerID_);

            var head:Int = player.at(head_);
            var bodyFirst:Int = player.at(bodyFirst_);

            if (head != Aspect.NULL) {
                var playerHead:BoardNode = getNode(head);
                if (playerHead.value.at(occupier_) != playerID || playerHead.value.at(isFilled_) == Aspect.FALSE) {

                    // Destroy the head and body

                    player.mod(head_, Aspect.NULL);
                    var bodyNode:BoardNode = getNode(bodyFirst);
                    if (bodyNode != null && bodyNode.value.at(occupier_) == playerID) for (node in bodyNode.boardListToArray(state.nodes, bodyNext_)) killCell(node, maxFreshness);
                    player.mod(bodyFirst_, Aspect.NULL);
                }
            }

        }

        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    function killCell(node:BoardNode, maxFreshness:Int):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);
        node.value.mod(freshness_, maxFreshness);

        node.removeNode(state.nodes, bodyNext_, bodyPrev_);
    }
}

