package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

class CavityRule extends Rule {

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
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    var remainingNodes:Int;

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
        var maxFreshness:Int = state.aspects[maxFreshness_] + 1;
        for (player in eachPlayer()) remapCavities(player, maxFreshness);
        state.aspects[maxFreshness_] = maxFreshness;
        signalEvent();
    }

    private function remapCavities(player:AspectSet, maxFreshness:Int):Void {

        // We destroy the existing cavity list
        var cavityFirst:Int = player[cavityFirst_];
        var oldCavityNodes:Array<AspectSet> = [];
        if (cavityFirst != Aspect.NULL) {
            oldCavityNodes = getNode(cavityFirst).listToAssocArray(state.nodes, cavityNext_, ident_);
            for (node in oldCavityNodes) if (node != null) clearCavityCell(node, maxFreshness);
            player[cavityFirst_] = Aspect.NULL;
        }

        var cavityNodes:Array<AspectSet> = [];

        // Find edge nodes of current player
        var bodyNode:AspectSet = getNode(player[bodyFirst_]);
        var edgeNodes:Array<AspectSet> = bodyNode.listToArray(state.nodes, bodyNext_).filter(hasFreeEdge);

        var allEdges:Map<String, Int> = new Map();
        var groups:Array<Array<String>> = [];
        var groupAngles:Array<Int> = [];
        var currentGroupIndex:Int = 0;
        var currentGroup:Array<String> = null;
        var currentEdge:String = null;

        // For each edge node,
        for (edgeNode in edgeNodes) {
            var edgeLocus = getNodeLocus(edgeNode);
            // For each empty ortho neighbor,
            for (direction in GridUtils.orthoDirections()) {
                var neighbor = edgeLocus.neighbors[direction];
                if (neighbor.value[isFilled_] == Aspect.FALSE) {
                    // make an edge that's in-no-group
                    allEdges['${getID(edgeNode)}/$direction'] = -1;
                }
            }
        }

        // For each edge,
        for (edge in allEdges.keys()) {
            // if edge is in-no-group,
            if (allEdges[edge] != -1) continue;

            // make a new group
            currentGroupIndex = groups.length;
            currentGroup = [];
            groups.push(currentGroup);
            groupAngles.push(0);

            // current edge is edge
            currentEdge = edge;
            // while (current edge is in-no-group)
            while (currentEdge != null && allEdges[currentEdge] == -1) {
                // current group: add current edge
                allEdges[currentEdge] = currentGroupIndex;
                currentGroup.push(currentEdge);

                var bits:Array<String> = currentEdge.split('/');
                var inID:Int = Std.parseInt(bits[0]);
                var direction:Int = Std.parseInt(bits[1]);

                var changeInDirection:Int = 0;
                var nextDirection:Int = 0;
                var nextEdge:String = null;

                {
                    changeInDirection = -2;
                    nextDirection = (direction + 6) % 8;
                    nextEdge = '${getID(getLocus(inID).neighbors[(direction + 1) % 8].value)}/$nextDirection';
                }
                if (allEdges[nextEdge] == null)
                {
                    changeInDirection = 0;
                    nextDirection = direction;
                    nextEdge = '${getID(getLocus(inID).neighbors[(direction + 2) % 8].value)}/$nextDirection';
                }
                if (allEdges[nextEdge] == null)
                {
                    changeInDirection = 2;
                    nextDirection = (direction + 2) % 8;
                    nextEdge = '$inID/$nextDirection';
                }

                if (allEdges[nextEdge] == null) {
                    currentEdge = null;
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

        for (ike in 0...groups.length) {
            if (groupAngles[ike] == -8) {
                // Add its interior to the cavityNodes
                var bits:Array<String> = groups[ike][0].split('/');
                var firstLocus:BoardLocus = getLocus(Std.parseInt(bits[0]));
                firstLocus = firstLocus.neighbors[Std.parseInt(bits[1])];
                for (locus in firstLocus.getGraphSequence(true, isEmpty)) cavityNodes.push(locus.value);
            }
        }

        var playerID:Int = getID(player);

        if (cavityNodes.length > 0) {

            // Cavity nodes that haven't changed don't get freshened
            for (node in cavityNodes) createCavity(playerID, oldCavityNodes[getID(node)] != null ? 0 : maxFreshness, node);

            cavityNodes.chainByAspect(ident_, cavityNext_, cavityPrev_);
            player[cavityFirst_] = cavityNodes[0][ident_];

            // Cavities affect the player's total area:
            var totalArea:Int = player[totalArea_] + cavityNodes.length;
            player[totalArea_] = totalArea;
        }
    }

    inline function hasFreeEdge(node:AspectSet):Bool {
        var exists:Bool = false;

        for (neighbor in getNodeLocus(node).orthoNeighbors()) {
            if (neighbor.value[isFilled_] == Aspect.FALSE) {
                exists = true;
                break;
            }
        }

        return exists;
    }

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
