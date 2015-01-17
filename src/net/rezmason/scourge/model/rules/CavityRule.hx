package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.Pointers;

class CavityRule extends RopesRule<Void> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.CAVITY_NEXT) var cavityNext_;
    @node(BodyAspect.CAVITY_PREV) var cavityPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.CAVITY_FIRST) var cavityFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    var allEdges:Array<Int> = [];
    var groupFirstEdges:Array<Int> = [];
    var groupAngles:Array<Int> = [];
    var cavityNodes:Array<AspectSet> = [];

    override private function _chooseMove(choice:Int):Void {
        var maxFreshness:Int = state.globals[maxFreshness_] + 1;
        for (player in eachPlayer()) eraseCavities(player, maxFreshness);
        for (player in eachPlayer()) makeCavities(player, maxFreshness);
        state.globals[maxFreshness_] = maxFreshness;
        onSignal();
    }

    private function eraseCavities(player:AspectSet, maxFreshness):Void {
        var cavityFirst:Int = player[cavityFirst_];
        var oldCavityNodes:Array<AspectSet> = [];
        if (cavityFirst != Aspect.NULL) {
            oldCavityNodes = getNode(cavityFirst).listToAssocArray(state.nodes, cavityNext_, ident_);
            for (node in oldCavityNodes) if (node != null) clearCavityCell(node, maxFreshness);
            player[cavityFirst_] = Aspect.NULL;
        }
    }

    private function makeCavities(player:AspectSet, maxFreshness:Int):Void {

        var edgeGroupIDs:Array<Null<Int>> = [];
        var numEdges:Int = 0;
        var numGroups:Int = 0;
        var currentGroupIndex:Int = 0;
        var currentEdge:Int = 0;

        // Find edge nodes of current player
        var bodyNode:AspectSet = getNode(player[bodyFirst_]);

        if (bodyNode != null) {
            var occupier:Int = bodyNode[occupier_];
            var edgeNodes:Array<AspectSet> = bodyNode.listToArray(state.nodes, bodyNext_);
            edgeNodes = edgeNodes.filter(hasDifferentNeighbor.bind(occupier));

            // For each edge node,
            for (edgeNode in edgeNodes) {
                var edgeLocus = getNodeLocus(edgeNode);
                // For each empty ortho neighbor,
                for (direction in GridUtils.orthoDirections()) {
                    var neighbor = edgeLocus.neighbors[direction];
                    if (neighbor.value[isFilled_] == Aspect.FALSE || neighbor.value[occupier_] != occupier) {
                        // make an edge that's in-no-group
                        currentEdge = makeEdge(getID(edgeNode), direction);
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
                    nextEdge = makeEdge(getID(getLocus(inID).neighbors[(direction + 1) % 8].value), nextDirection);
                }
                if (edgeGroupIDs[nextEdge] == null)
                {
                    changeInDirection = 0;
                    nextDirection = direction;
                    nextEdge = makeEdge(getID(getLocus(inID).neighbors[(direction + 2) % 8].value), nextDirection);
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

        var loci:Array<BoardLocus> = [];

        for (ike in 0...numGroups) {
            if (groupAngles[ike] == -8) {
                // Add its interior to the cavityNodes
                currentEdge = groupFirstEdges[ike];
                loci.push(getLocus(getEdgeID(currentEdge)).neighbors[getEdgeDirection(currentEdge)]);
            }
        }

        var numCavityNodes:Int = 0;
        for (locus in loci.expandGraphSequence(true, isEmpty)) {
            cavityNodes[numCavityNodes] = locus.value;
            numCavityNodes++;
        }

        if (numCavityNodes > 0) {

            cavityNodes.splice(numCavityNodes, cavityNodes.length);

            // Cavity nodes that haven't changed don't get freshened
            var playerID:Int = getID(player);
            for (node in cavityNodes) createCavity(playerID, maxFreshness, node);

            cavityNodes.chainByAspect(ident_, cavityNext_, cavityPrev_);
            player[cavityFirst_] = cavityNodes[0][ident_];

            // Cavities affect the player's total area:
            var totalArea:Int = player[totalArea_] + cavityNodes.length;
            player[totalArea_] = totalArea;
        }
    }

    inline function hasDifferentNeighbor(allegiance:Int, node:AspectSet):Bool {
        var exists:Bool = false;

        for (neighbor in getNodeLocus(node).orthoNeighbors()) {
            if (neighbor == null || neighbor.value[isFilled_] == Aspect.FALSE || neighbor.value[occupier_] != allegiance) {
                exists = true;
                break;
            }
        }

        return exists;
    }

    inline function makeEdge(id:Int, direction:Int):Int return (id << 3) | (direction & 7);
    inline function getEdgeID(edge:Int):Int return edge >> 3;
    inline function getEdgeDirection(edge:Int):Int return edge & 7;

    inline function isEmpty(me:AspectSet, you:AspectSet):Bool return me[isFilled_] == Aspect.FALSE;

    inline function createCavity(occupier:Int, maxFreshness:Int, node:AspectSet):Void {
        node[isFilled_] = Aspect.FALSE;
        node[occupier_] = occupier;
        node[freshness_] = maxFreshness;
    }

    inline function clearCavityCell(node:AspectSet, maxFreshness:Int):Void {
        if (node[isFilled_] == Aspect.FALSE) node[occupier_] = Aspect.NULL;
        node[freshness_] = maxFreshness;
        node.removeSet(state.nodes, cavityNext_, cavityPrev_);
    }
}
