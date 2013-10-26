package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

//using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessBodyRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        // trace(state.spitBoard(plan));

        var maxFreshness:Int = state.aspects[maxFreshness_] + 1;

        // Check each player to see if they still have head nodes

        for (player in eachPlayer()) {
            var playerID:Int = getID(player);

            var head:Int = player[head_];

            if (head != Aspect.NULL) {
                var bodyFirst:Int = player[bodyFirst_];
                var playerHead:BoardNode = getNode(head);
                if (playerHead.value[occupier_] != playerID || playerHead.value[isFilled_] == Aspect.FALSE) {

                    // Destroy the head and body

                    player[head_] = Aspect.NULL;
                    var bodyNode:BoardNode = getNode(bodyFirst);
                    for (node in bodyNode.boardListToArray(state.nodes, bodyNext_)) killCell(node, maxFreshness);
                    player[bodyFirst_] = Aspect.NULL;
                }
            }

        }

        state.aspects[maxFreshness_] = maxFreshness;

        // trace(state.spitBoard(plan));
        // trace('---');
    }

    function killCell(node:BoardNode, maxFreshness:Int):Void {
        node.value[isFilled_] = Aspect.FALSE;
        node.value[occupier_] = Aspect.NULL;
        node.value[freshness_] = maxFreshness;

        node.removeNode(state.nodes, bodyNext_, bodyPrev_);
    }
}

