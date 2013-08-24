package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
//import net.rezmason.ropes.GridNode;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class CavityRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.CAVITY_NEXT) var cavityNext_;
    @node(BodyAspect.CAVITY_PREV) var cavityPrev_;
    @node(IdentityAspect.NODE_ID) var nodeID_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.CAVITY_FIRST) var cavityFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(IdentityAspect.PLAYER_ID) var playerID_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    var remainingNodes:Int;

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
        var maxFreshness:Int = state.aspects[maxFreshness_] + 1;
        for (player in eachPlayer()) remapCavities(player[playerID_], maxFreshness);
        state.aspects[maxFreshness_] = maxFreshness;
    }

    private function remapCavities(playerID:Int, maxFreshness:Int):Void {
        var player:AspectSet = getPlayer(playerID);

        // We destroy the existing cavity list
        var cavityFirst:Int = player[cavityFirst_];
        var oldCavityNodes:Array<BoardNode> = [];
        if (cavityFirst != Aspect.NULL) {
            oldCavityNodes = getNode(cavityFirst).boardListToArray(state.nodes, bodyNext_);
            for (node in oldCavityNodes) clearCavityCell(node, maxFreshness);
            player[cavityFirst_] = Aspect.NULL;
        }

        // No one cares about your cavities if you're dead
        if (player[head_] == Aspect.NULL) return;

        // Now for the fun part: finding all the cavity nodes.

        var cavityNodes:Array<BoardNode> = [];
        var body:Array<BoardNode> = getNode(player[bodyFirst_]).boardListToArray(state.nodes, bodyNext_);
        var head:BoardNode = getNode(player[head_]);

        // We're going to search the board for ALL nodes UNTIL we have found all body nodes
        // This takes advantage of the FILO search pattern of GridUtils.getGraph

        remainingNodes = body.length - 1;
        var widePerimeter:Array<BoardNode> = head.getGraph(true, isWithinPerimeter.bind(playerID));

        // After reversing the search results, they are sorted in the order of most-outside to least-outside
        widePerimeter.reverse();

        var nodeIDs:Map<Int, Bool> = new Map();
        for (node in widePerimeter) nodeIDs[node.value[nodeID_]] = true;

        var empties:Array<BoardNode> = [];

        // Searching from the outside in, we remove exposed empty nodes from the set
        for (ike in 0...widePerimeter.length) {

            var node:BoardNode = widePerimeter[ike];

            var occupier:Int = node.value[occupier_];
            var isFilled:Int = node.value[isFilled_];

            // Dismiss filled nodes
            if (isFilled == Aspect.TRUE) {
                // remove enemy filled nodes from the nodeIDs
                if (occupier != playerID) nodeIDs.remove(node.value[nodeID_]);
            } else {
                empties.push(node);
            }
        }

        // Of those cells, we repeatedly remove cells which are in fact still exposed
        // TODO: use getGraph for this instead
        var lastLength:Int = 0;
        while (empties.length != lastLength) {
            lastLength = empties.length;
            var newEmpties:Array<BoardNode> = [];
            for (node in empties) {
                newEmpties.push(node);
                for (neighbor in node.orthoNeighbors()) {
                    if (neighbor == null || !nodeIDs.exists(neighbor.value[nodeID_])) {
                        nodeIDs.remove(node.value[nodeID_]);
                        newEmpties.pop();
                        break;
                    }
                }
            }
            empties = newEmpties;
        }

        // The cavities are the nodes that remain and are empty
        cavityNodes = empties;

        if (cavityNodes.length > 0) {

            // Cavity nodes that haven't changed don't get freshened
            for (node in cavityNodes) createCavity(playerID, oldCavityNodes.has(node) ? 0 : maxFreshness, node);

            cavityNodes.chainByAspect(nodeID_, cavityNext_, cavityPrev_);
            player[cavityFirst_] = cavityNodes[0].value[nodeID_];

            // Cavities affect the player's total area:
            var totalArea:Int = player[totalArea_] + cavityNodes.length;
            player[totalArea_] = totalArea;
        }
    }

    // This comparator doesn't actually compare aspect sets; it counts the number
    // of aspects it has found, and ends the search when they're all found
    function isWithinPerimeter(allegiance:Int, me:AspectSet, you:AspectSet):Bool {
        if (remainingNodes <= 0) return false;
        if (me[isFilled_] == Aspect.TRUE && me[occupier_] == allegiance) remainingNodes--;
        return true;
    }

    inline function createCavity(occupier:Int, maxFreshness:Int, node:BoardNode):Void {
        node.value[isFilled_] = Aspect.FALSE;
        node.value[occupier_] = occupier;
        node.value[freshness_] = maxFreshness;
    }

    inline function clearCavityCell(node:BoardNode, maxFreshness:Int):Void {
        node.value[isFilled_] = Aspect.FALSE;
        node.value[occupier_] = Aspect.NULL;
        node.value[freshness_] = maxFreshness;
        node.removeNode(state.nodes, cavityNext_, cavityPrev_);
    }
}
