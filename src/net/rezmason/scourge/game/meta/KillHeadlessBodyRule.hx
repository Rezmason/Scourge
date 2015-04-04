package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;

using Lambda;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessBodyRule extends BaseRule<Dynamic> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    override private function _chooseMove(choice:Int):Void {

        // trace(state.spitBoard(plan));

        var maxFreshness:Int = state.global[maxFreshness_];

        // Check each player to see if they still have head nodes

        for (player in eachPlayer()) {
            var playerID:Int = getID(player);

            var head:Int = player[head_];

            if (head != NULL) {
                var bodyFirst:Int = player[bodyFirst_];
                var playerHead:AspectSet = getNode(head);
                if (playerHead[occupier_] != playerID || playerHead[isFilled_] == FALSE) {

                    // Destroy the head and body

                    player[head_] = NULL;
                    var bodyNode:AspectSet = getNode(bodyFirst);
                    for (node in bodyNode.listToArray(state.nodes, bodyNext_)) killCell(node, maxFreshness);
                    player[bodyFirst_] = NULL;
                    maxFreshness++;
                }
            }

        }

        state.global[maxFreshness_] = maxFreshness;

        // trace(state.spitBoard(plan));
        // trace('---');
    }

    function killCell(node:AspectSet, maxFreshness:Int):Void {
        node[isFilled_] = FALSE;
        node[occupier_] = NULL;
        node[freshness_] = maxFreshness;

        node.removeSet(state.nodes, bodyNext_, bodyPrev_);
    }
}

