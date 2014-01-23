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
        for (player in eachPlayer()) remapCavities(getID(player), maxFreshness);
        state.aspects[maxFreshness_] = maxFreshness;
        signalEvent();
    }

    private function remapCavities(playerID:Int, maxFreshness:Int):Void {

        var player:AspectSet = getPlayer(playerID);

        // We destroy the existing cavity list
        var cavityFirst:Int = player[cavityFirst_];
        var oldCavityNodes:Map<Int, AspectSet> = new Map();
        if (cavityFirst != Aspect.NULL) {
            oldCavityNodes = getNode(cavityFirst).listToMap(state.nodes, cavityNext_, ident_);
            for (node in oldCavityNodes) clearCavityCell(node, maxFreshness);
            player[cavityFirst_] = Aspect.NULL;
        }

        var cavityNodes:Array<AspectSet> = [];

        // No one cares about your cavities if you're dead
        if (player[head_] != Aspect.NULL) {

            // Now for the fun part: finding all the cavity nodes.

            var body:Array<AspectSet> = getNode(player[bodyFirst_]).listToArray(state.nodes, bodyNext_);
            var head:BoardLocus = getLocus(player[head_]);

            // We're going to search the board for ALL nodes UNTIL we have found all body nodes
            // This takes advantage of the FILO search pattern of GridUtils.getGraph

            remainingNodes = body.length - 1;
            var widePerimeter:Array<BoardLocus> = head.getGraphSequence(true, isWithinPerimeter.bind(playerID));

            // After reversing the search results, they are sorted in the order of most-outside to least-outside
            widePerimeter.reverse();

            var nodeIDs:Map<Int, Bool> = new Map();
            for (locus in widePerimeter) nodeIDs[getID(locus.value)] = true;

            var empties:Array<AspectSet> = [];

            // Searching from the outside in, we remove exposed empty nodes from the set
            for (ike in 0...widePerimeter.length) {

                var locus:BoardLocus = widePerimeter[ike];

                var occupier:Int = locus.value[occupier_];
                var isFilled:Int = locus.value[isFilled_];

                // Dismiss filled nodes
                if (isFilled == Aspect.TRUE) {
                    // remove enemy filled nodes from the nodeIDs
                    if (occupier != playerID) nodeIDs.remove(getID(locus.value));
                } else {
                    empties.push(locus.value);
                }
            }

            // Of those cells, we repeatedly remove cells which are in fact still exposed
            // TODO: use getGraph for this instead
            var lastLength:Int = 0;
            while (empties.length != lastLength) {
                lastLength = empties.length;
                var newEmpties:Array<AspectSet> = [];
                for (node in empties) {
                    newEmpties.push(node);
                    for (neighbor in getNodeLocus(node).orthoNeighbors()) {
                        if (neighbor == null || !nodeIDs.exists(getID(neighbor.value))) {
                            nodeIDs.remove(getID(node));
                            newEmpties.pop();
                            break;
                        }
                    }
                }
                empties = newEmpties;
            }

            // The cavities are the nodes that remain and are empty
            cavityNodes = empties;
        }

        if (cavityNodes.length > 0) {

            // Cavity nodes that haven't changed don't get freshened
            for (node in cavityNodes) createCavity(playerID, oldCavityNodes.exists(getID(node)) ? 0 : maxFreshness, node);

            cavityNodes.chainByAspect(ident_, cavityNext_, cavityPrev_);
            player[cavityFirst_] = cavityNodes[0][ident_];

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
