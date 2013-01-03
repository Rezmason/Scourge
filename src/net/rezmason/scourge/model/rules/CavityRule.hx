package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
//import net.rezmason.ropes.GridNode;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class CavityRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.CAVITY_NEXT) var cavityNext_;
    @node(BodyAspect.CAVITY_PREV) var cavityPrev_;
    @node(BodyAspect.NODE_ID) var nodeID_;
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
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int = 0):Void {
        super.chooseOption(choice);
        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;
        for (ike in 0...state.players.length) remapCavities(ike, maxFreshness);
        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    private function remapCavities(playerIndex:Int, maxFreshness:Int):Void {
        var player:AspectSet = state.players[playerIndex];

        // We destroy the existing cavity list
        var cavityFirst:Int = player.at(cavityFirst_);
        var oldCavityNodes:Array<BoardNode> = [];
        if (cavityFirst != Aspect.NULL) {
            oldCavityNodes = state.nodes[cavityFirst].boardListToArray(state.nodes, bodyNext_);
            for (node in oldCavityNodes) clearCavityCell(node, maxFreshness);
            player.mod(cavityFirst_, Aspect.NULL);
        }

        // No one cares about your cavities if you're dead
        if (player.at(head_) == Aspect.NULL) return;

        // Now for the fun part: finding all the cavity nodes.

        var cavityNodes:Array<BoardNode> = [];
        var body:Array<BoardNode> = state.nodes[player.at(bodyFirst_)].boardListToArray(state.nodes, bodyNext_);
        var head:BoardNode = state.nodes[player.at(head_)];

        // We're going to search the board for ALL nodes UNTIL we have found all body nodes
        // This takes advantage of the FILO search pattern of GridUtils.getGraph

        remainingNodes = body.length - 1;
        var widePerimeter:Array<BoardNode> = head.getGraph(true, callback(isWithinPerimeter, playerIndex));

        // After reversing the search results, they are sorted in the order of most-outside to least-outside
        widePerimeter.reverse();

        var nodeIDs:IntHash<Bool> = new IntHash<Bool>();
        for (node in widePerimeter) nodeIDs.set(node.value.at(nodeID_), true);

        var empties:Array<BoardNode> = [];

        // Searching from the outside in, we remove exposed empty nodes from the set
        for (ike in 0...widePerimeter.length) {

            var node:BoardNode = widePerimeter[ike];

            var occupier:Int = node.value.at(occupier_);
            var isFilled:Int = node.value.at(isFilled_);

            // Dismiss filled nodes
            if (isFilled == Aspect.TRUE) {
                // remove enemy filled nodes from the nodeIDs
                if (occupier != playerIndex) nodeIDs.remove(node.value.at(nodeID_));
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
                    if (neighbor == null || !nodeIDs.exists(neighbor.value.at(nodeID_))) {
                        nodeIDs.remove(node.value.at(nodeID_));
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
            for (node in cavityNodes) createCavity(playerIndex, oldCavityNodes.has(node) ? 0 : maxFreshness, node);

            cavityNodes.chainByAspect(nodeID_, cavityNext_, cavityPrev_);
            player.mod(cavityFirst_, cavityNodes[0].value.at(nodeID_));

            // Cavities affect the player's total area:
            var totalArea:Int = player.at(totalArea_) + cavityNodes.length;
            player.mod(totalArea_, totalArea);
        }
    }

    // This comparator doesn't actually compare aspect sets; it counts the number
    // of aspects it has found, and ends the search when they're all found
    function isWithinPerimeter(allegiance:Int, me:AspectSet, you:AspectSet):Bool {
        if (remainingNodes <= 0) return false;
        if (me.at(isFilled_) == Aspect.TRUE && me.at(occupier_) == allegiance) remainingNodes--;
        return true;
    }

    inline function createCavity(occupier:Int, maxFreshness:Int, node:BoardNode):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, occupier);
        node.value.mod(freshness_, maxFreshness);
    }

    inline function clearCavityCell(node:BoardNode, maxFreshness:Int):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);
        node.value.mod(freshness_, maxFreshness);
        node.removeNode(state.nodes, cavityNext_, cavityPrev_);
    }
}
