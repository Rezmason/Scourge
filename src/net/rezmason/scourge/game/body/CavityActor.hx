package net.rezmason.scourge.game.body;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.meta.FreshnessAspect;

using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.aspect.AspectUtils;

class CavityActor extends Actor<Dynamic> {

    @space(BodyAspect.BODY_NEXT) var bodyNext_;
    @space(BodyAspect.CAVITY_NEXT, true) var cavityNext_;
    @space(BodyAspect.CAVITY_PREV, true) var cavityPrev_;
    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @space(OwnershipAspect.IS_FILLED, true) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.CAVITY_FIRST, true) var cavityFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA, true) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;

    var allEdges:Array<Int> = [];
    var groupFirstEdges:Array<Int> = [];
    var groupAngles:Array<Int> = [];
    var cavitySpaces:Array<Space> = [];

    override private function _chooseMove(_):Void {
        var maxFreshness:Int = state.global[maxFreshness_];
        var boardChanged = false;
        for (player in eachPlayer()) boardChanged = eraseCavities(player, maxFreshness) || boardChanged;
        for (player in eachPlayer()) boardChanged =  makeCavities(player, maxFreshness) || boardChanged;
        if (boardChanged) state.global[maxFreshness_] = maxFreshness + 1;
        signalChange();
    }

    private function eraseCavities(player:Player, maxFreshness):Bool {
        var cavityFirst:Int = player[cavityFirst_];
        if (cavityFirst != NULL) {
            var oldCavitySpaces = getSpace(cavityFirst).listToAssocArray(state.spaces, cavityNext_, spaceIdent_);
            for (space in oldCavitySpaces) if (space != null) clearCavityCell(space, maxFreshness);
            player[cavityFirst_] = NULL;
        }
        return cavityFirst != NULL;
    }

    private function makeCavities(player:Player, maxFreshness:Int):Bool {

        var edgeGroupIDs:Array<Null<Int>> = [];
        var numEdges:Int = 0;
        var numGroups:Int = 0;
        var currentGroupIndex:Int = 0;
        var currentEdge:Int = 0;

        // Find edge spaces of current player
        var bodySpace:Space = getSpace(player[bodyFirst_]);

        if (bodySpace != null) {
            var occupier:Int = bodySpace[occupier_];
            var edgeSpaces = [];
            for (space in bodySpace.listToArray(state.spaces, bodyNext_)) {
                var hasDifferentNeighbor = false;
                for (neighbor in getSpaceCell(space).orthoNeighbors()) {
                    if (neighbor == null || neighbor.value[isFilled_] == FALSE || neighbor.value[occupier_] != occupier) {
                        hasDifferentNeighbor = true;
                        break;
                    }
                }
                if (hasDifferentNeighbor) edgeSpaces.push(space);
            }

            // For each edge space,
            for (edgeSpace in edgeSpaces) {
                var edgeCell = getSpaceCell(edgeSpace);
                // For each empty ortho neighbor,
                for (direction in GridUtils.orthoDirections()) {
                    var neighbor = edgeCell.neighbors[direction];
                    if (neighbor.value[isFilled_] == FALSE || neighbor.value[occupier_] != occupier) {
                        // make an edge that's in-no-group
                        currentEdge = makeEdge(getID(edgeSpace), direction);
                        edgeGroupIDs[currentEdge] = -1;
                        allEdges[numEdges] = currentEdge;
                        numEdges++;
                    }
                }
            }
        }

        // For each edge,
        for (ike in 0...numEdges) {
            currentEdge = allEdges[ike];

            // if edge is in-no-group,
            if (edgeGroupIDs[currentEdge] != -1) continue;

            // make a new group
            currentGroupIndex = numGroups;
            groupFirstEdges[currentGroupIndex] = currentEdge;
            groupAngles[currentGroupIndex] = 0;
            numGroups++;

            // while (current edge is in-no-group)
            while (currentEdge != -1 && edgeGroupIDs[currentEdge] == -1) {
                // current group: add current edge
                edgeGroupIDs[currentEdge] = currentGroupIndex;

                var inID:Int = getEdgeID(currentEdge);
                var direction:Int = getEdgeDirection(currentEdge);

                var changeInDirection:Int = 0;
                var nextDirection:Int = 0;
                var nextEdge:Int = -1;

                {
                    changeInDirection = -2;
                    nextDirection = (direction + 6) % 8;
                    nextEdge = makeEdge(getID(getCell(inID).neighbors[(direction + 1) % 8].value), nextDirection);
                }
                if (edgeGroupIDs[nextEdge] == null)
                {
                    changeInDirection = 0;
                    nextDirection = direction;
                    nextEdge = makeEdge(getID(getCell(inID).neighbors[(direction + 2) % 8].value), nextDirection);
                }
                if (edgeGroupIDs[nextEdge] == null)
                {
                    changeInDirection = 2;
                    nextDirection = (direction + 2) % 8;
                    nextEdge = makeEdge(inID, nextDirection);
                }

                if (edgeGroupIDs[nextEdge] == null) {
                    currentEdge = -1;
                } else {
                    // add 'angle change' to current group's angle
                    groupAngles[currentGroupIndex] += changeInDirection;
                    currentEdge = nextEdge;
                }
            }
            // if group of current edge is current group
                // Closed loop!
            // else
                // Error, probably!
        }

        var cells:Array<BoardCell> = [];

        for (ike in 0...numGroups) {
            if (groupAngles[ike] == -8) {
                // Add its interior to the cavitySpaces
                currentEdge = groupFirstEdges[ike];
                cells.push(getCell(getEdgeID(currentEdge)).neighbors[getEdgeDirection(currentEdge)]);
            }
        }

        var numCavitySpaces:Int = 0;
        for (cell in cells.select().expand(true, isEmpty)) {
            cavitySpaces[numCavitySpaces] = cell.value;
            numCavitySpaces++;
        }

        if (numCavitySpaces > 0) {

            cavitySpaces.splice(numCavitySpaces, cavitySpaces.length);

            // Cavity spaces that haven't changed don't get freshened
            var playerID:Int = getID(player);
            for (space in cavitySpaces) createCavity(playerID, maxFreshness, space);

            cavitySpaces.chainByAspect(spaceIdent_, cavityNext_, cavityPrev_);
            player[cavityFirst_] = getID(cavitySpaces[0]);

            // Cavities affect the player's total area:
            var totalArea:Int = player[totalArea_] + cavitySpaces.length;
            player[totalArea_] = totalArea;
        }

        return numCavitySpaces > 0;
    }

    inline function makeEdge(id:Int, direction:Int):Int return (id << 3) | (direction & 7);
    inline function getEdgeID(edge:Int):Int return edge >> 3;
    inline function getEdgeDirection(edge:Int):Int return edge & 7;

    inline function isEmpty(me:Space, you:Space):Bool return me[isFilled_] == FALSE;

    inline function createCavity(occupier:Int, maxFreshness:Int, space:Space):Void {
        space[isFilled_] = FALSE;
        space[occupier_] = occupier;
        space[freshness_] = maxFreshness;
    }

    inline function clearCavityCell(space:Space, maxFreshness:Int):Void {
        if (space[isFilled_] == FALSE) space[occupier_] = NULL;
        space[freshness_] = maxFreshness;
        space.removeSet(state.spaces, cavityNext_, cavityPrev_);
    }
}
