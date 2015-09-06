package net.rezmason.scourge.game.body;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.ds.ShitList;

using Lambda;
using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.pointers.Pointers;

class EatRule extends BaseRule<EatParams> {

    @space(BodyAspect.BODY_NEXT, true) var bodyNext_;
    @space(BodyAspect.BODY_PREV, true) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BodyAspect.BODY_FIRST, true) var bodyFirst_;
    @player(BodyAspect.HEAD, true) var head_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _chooseMove(choice:Int):Void {

        var currentPlayer:Int = state.global[currentPlayer_];
        var head:Int = getPlayer(currentPlayer)[head_];
        var bodySpace:Space = getSpace(getPlayer(currentPlayer)[bodyFirst_]);
        var maxFreshness:Int = state.global[maxFreshness_];

        // List all the players' heads

        var headIndices:Array<Int> = [];
        for (player in eachPlayer()) headIndices.push(player[head_]);

        // Find all fresh body spaces of the current player

        var newSpaces:ShitList<Space> = new ShitList(bodySpace.listToArray(state.spaces, bodyNext_).filter(isFresh));

        var newSpacesByID:Array<Space> = [];
        for (space in newSpaces) newSpacesByID[getID(space)] = space;

        var eatenSpaces:Array<Space> = [];
        var eatenSpaceGroups:Array<Array<Space>> = [];

        // We search space for uninterrupted regions of player cells that begin and end
        // with cells of the current player. We propagate these searches from cells
        // that have been freshly eaten, starting with the current player's fresh spaces

        var space:Space = newSpaces.pop();
        if (space != null) newSpacesByID[getID(space)] = null;
        while (space != null) {
            // search in all directions
            for (direction in directionsFor(params.eatOrthogonallyOnly)) {
                var pendingSpaces:Array<Space> = [];
                var cell:BoardCell = getSpaceCell(space);
                for (scout in cell.walk(direction)) {
                    if (scout == cell) continue; // starting space
                    if (scout.value[isFilled_] > 0) {
                        var scoutOccupier:Int = scout.value[occupier_];
                        if (scoutOccupier == currentPlayer || eatenSpaces[getID(scout.value)] != null) {
                            // Add spaces to the eaten region
                            for (pendingSpace in pendingSpaces) {
                                var playerID:Int = headIndices.indexOf(getID(pendingSpace));
                                if (playerID != -1 && params.takeBodiesFromEatenHeads) pendingSpaces.absorb(getBody(playerID)); // body-from-head eating
                                else if (params.eatRecursively && newSpacesByID[getID(pendingSpace)] == null) newSpaces.add(pendingSpace); // recursive eating

                                eatenSpaces[getID(pendingSpace)] = pendingSpace;
                            }
                            eatenSpaceGroups.push(pendingSpaces);
                            break;
                        } else if (headIndices[scoutOccupier] == getID(scout.value)) {
                            // Only eat heads if the params specifies this
                            if (params.eatHeads) pendingSpaces.push(scout.value);
                            //else break;
                        } else {
                            pendingSpaces.push(scout.value);
                        }
                    } else {
                        break;
                    }
                }
            }
            space = newSpaces.pop();
            if (space != null) newSpacesByID[getID(space)] = null;
        }

        // Update cells in the eaten region
        for (group in eatenSpaceGroups) {
            var spacesEaten = false;
            for (space in group) {
                if (space != null && space[occupier_] != currentPlayer) {
                    space[occupier_] = currentPlayer;
                    space[freshness_] = maxFreshness;
                    spacesEaten = true;
                }
            }
            if (spacesEaten) maxFreshness++;
        }

        state.global[maxFreshness_] = maxFreshness;

        // Clean up the bodyFirst and head pointers for opponent players
        for (player in eachPlayer()) {
            var playerID:Int = getID(player);
            if (playerID == currentPlayer) continue;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != NULL) {
                var body:Array<Space> = getSpace(bodyFirst).listToArray(state.spaces, bodyNext_);
                var revisedBody:Array<Space> = [];
                for (space in body) {
                    if (space[isFilled_] == TRUE && space[occupier_] == playerID) revisedBody.push(space);
                }
                revisedBody.chainByAspect(spaceIdent_, bodyNext_, bodyPrev_);
                if (revisedBody.length > 0) player[bodyFirst_] = getID(revisedBody[0]);
                else player[bodyFirst_] = NULL;
            }

            var head:Int = player[head_];
            if (head != NULL) {
                var headSpace:Space = getSpace(head);
                if (headSpace[occupier_] != playerID) player[head_] = NULL;
            }
        }

        // Add the filled eaten spaces to the current player body
        for (space in eatenSpaces) {
            if (space != null && space[isFilled_] == TRUE) {
                bodySpace = bodySpace.addSet(space, state.spaces, spaceIdent_, bodyNext_, bodyPrev_);
            }
        }
        getPlayer(currentPlayer)[bodyFirst_] = getID(bodySpace);
        signalChange();
    }

    function getBody(playerID:Int):Array<Space> {
        var bodySpace:Space = getSpace(getPlayer(playerID)[bodyFirst_]);
        return bodySpace.listToArray(state.spaces, bodyNext_);
    }

    function isLivingBodyNeighbor(me:Space, you:Space):Bool {
        if (me[isFilled_] == FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function isFresh(space:Space):Bool {
        return space[freshness_] != NULL;
    }

    function directionsFor(ortho:Bool):Iterator<Int> {
        return ortho ? GridUtils.orthoDirections() : GridUtils.allDirections();
    }
}

