package net.rezmason.scourge.model.body;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.meta.FreshnessAspect;

using Lambda;

using net.rezmason.ropes.aspect.AspectUtils;
using net.rezmason.ropes.grid.GridUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

class DecayRule extends RopesRule<DecayParams> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    override private function _chooseMove(choice:Int):Void {

        var maxFreshness:Int = state.global[maxFreshness_];

        // Grab all the player heads

        var heads:Array<BoardLocus> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != NULL && getNode(headIndex)[occupier_] == getID(player)) {
                heads.push(getLocus(headIndex));
            }
        }

        // Use the heads as starting points for a flood fill of connected living cells
        var livingBodyNeighbors:Array<BoardLocus> = heads.expandGraph(params.decayOrthogonallyOnly, isLivingBodyNeighbor);

        var cellDied = false;
        // Remove cells from player bodies
        for (player in eachPlayer()) {

            var totalArea:Int = 0;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != NULL) {
                for (node in getNode(bodyFirst).iterate(state.nodes, bodyNext_)) {
                    if (livingBodyNeighbors[getID(node)] == null) {
                        bodyFirst = killCell(node, maxFreshness, bodyFirst);
                        cellDied = true;
                    } else {
                        totalArea++;
                    }
                }
            }

            player[bodyFirst_] = bodyFirst;
            player[totalArea_] = totalArea;
        }

        state.global[maxFreshness_] = maxFreshness + (cellDied ? 1 : 0);
        signalChange();
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me[isFilled_] == FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function killCell(node:AspectSet, freshness:Int, firstIndex:Int):Int {
        node[isFilled_] = FALSE;
        node[occupier_] = NULL;
        node[freshness_] = freshness;

        var nextNode:AspectSet = node.removeSet(state.nodes, bodyNext_, bodyPrev_);
        if (firstIndex == getID(node)) {
            firstIndex = (nextNode == null) ? NULL : getID(nextNode);
        }
        return firstIndex;
    }
}

