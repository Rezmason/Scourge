package net.rezmason.scourge.game.body;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.meta.FreshnessAspect;

using Lambda;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.grid.GridUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

class DecayRule extends BaseRule<DecayParams> {

    @space(BodyAspect.BODY_NEXT) var bodyNext_;
    @space(BodyAspect.BODY_PREV) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS) var freshness_;
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    override private function _chooseMove(choice:Int):Void {

        var maxFreshness:Int = state.global[maxFreshness_];

        // Grab all the player heads

        var heads:Array<BoardCell> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != NULL && getSpace(headIndex)[occupier_] == getID(player)) {
                heads.push(getCell(headIndex));
            }
        }

        // Use the heads as starting points for a flood fill of connected living cells
        var livingBodyNeighbors:Array<BoardCell> = heads.expandGrid(params.decayOrthogonallyOnly, isLivingBodyNeighbor);

        var cellDied = false;
        // Remove cells from player bodies
        for (player in eachPlayer()) {

            var totalArea:Int = 0;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != NULL) {
                for (space in getSpace(bodyFirst).iterate(state.spaces, bodyNext_)) {
                    if (livingBodyNeighbors[getID(space)] == null) {
                        bodyFirst = killCell(space, maxFreshness, bodyFirst);
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

    function killCell(space:AspectSet, freshness:Int, firstIndex:Int):Int {
        space[isFilled_] = FALSE;
        space[occupier_] = NULL;
        space[freshness_] = freshness;

        var nextSpace:AspectSet = space.removeSet(state.spaces, bodyNext_, bodyPrev_);
        if (firstIndex == getID(space)) {
            firstIndex = (nextSpace == null) ? NULL : getID(nextSpace);
        }
        return firstIndex;
    }
}

