package net.rezmason.scourge.game.body;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.meta.FreshnessAspect;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.grid.GridUtils;

class DecayActor extends Actor<DecayParams> {

    @space(BodyAspect.BODY_NEXT, true) var bodyNext_;
    @space(BodyAspect.BODY_PREV, true) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @space(OwnershipAspect.IS_FILLED, true) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BodyAspect.BODY_FIRST, true) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA, true) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;

    override public function chooseMove(_):Void {

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
        var livingBodyNeighbors:BoardSelection = heads.select().expand(params.decayOrthogonallyOnly, isLivingBodyNeighbor);

        var cellDied = false;
        // Remove cells from player bodies
        for (player in eachPlayer()) {

            var totalArea:Int = 0;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != NULL) {
                for (space in getSpace(bodyFirst).iterate(state.spaces, bodyNext_)) {
                    if (!livingBodyNeighbors.contains(getID(space))) {
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

    function isLivingBodyNeighbor(me:Space, you:Space):Bool {
        if (me[isFilled_] == FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function killCell(space:Space, freshness:Int, firstIndex:Int):Int {
        space[isFilled_] = FALSE;
        space[occupier_] = NULL;
        space[freshness_] = freshness;

        var nextSpace = space.removeSet(state.spaces, bodyNext_, bodyPrev_);
        if (firstIndex == getID(space)) {
            firstIndex = (nextSpace == null) ? NULL : getID(nextSpace);
        }
        return firstIndex;
    }
}

