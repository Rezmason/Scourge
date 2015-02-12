package net.rezmason.scourge.game.body;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.ds.ShitList;

using Lambda;
using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

class EatCellsRule extends BaseRule<EatCellsParams> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _chooseMove(choice:Int):Void {

        var currentPlayer:Int = state.global[currentPlayer_];
        var head:Int = getPlayer(currentPlayer)[head_];
        var bodyNode:AspectSet = getNode(getPlayer(currentPlayer)[bodyFirst_]);
        var maxFreshness:Int = state.global[maxFreshness_];

        // List all the players' heads

        var headIndices:Array<Int> = [];
        for (player in eachPlayer()) headIndices.push(player[head_]);

        // Find all fresh body nodes of the current player

        var newNodes:ShitList<AspectSet> = new ShitList(bodyNode.listToArray(state.nodes, bodyNext_).filter(isFresh));

        var newNodesByID:Array<AspectSet> = [];
        for (node in newNodes) newNodesByID[getID(node)] = node;

        var eatenNodes:Array<AspectSet> = [];
        var eatenNodeGroups:Array<Array<AspectSet>> = [];

        // We search space for uninterrupted regions of player cells that begin and end
        // with cells of the current player. We propagate these searches from cells
        // that have been freshly eaten, starting with the current player's fresh nodes

        var node:AspectSet = newNodes.pop();
        if (node != null) newNodesByID[getID(node)] = null;
        while (node != null) {
            // search in all directions
            for (direction in directionsFor(params.eatOrthogonallyOnly)) {
                var pendingNodes:Array<AspectSet> = [];
                var locus:BoardLocus = getNodeLocus(node);
                for (scout in locus.walk(direction)) {
                    if (scout == locus) continue; // starting node
                    if (scout.value[isFilled_] > 0) {
                        var scoutOccupier:Int = scout.value[occupier_];
                        if (scoutOccupier == currentPlayer || eatenNodes[getID(scout.value)] != null) {
                            // Add nodes to the eaten region
                            for (pendingNode in pendingNodes) {
                                var playerID:Int = headIndices.indexOf(getID(pendingNode));
                                if (playerID != -1 && params.takeBodiesFromEatenHeads) pendingNodes.absorb(getBody(playerID)); // body-from-head eating
                                else if (params.eatRecursively && newNodesByID[getID(pendingNode)] == null) newNodes.add(pendingNode); // recursive eating

                                eatenNodes[getID(pendingNode)] = pendingNode;
                            }
                            eatenNodeGroups.push(pendingNodes);
                            break;
                        } else if (headIndices[scoutOccupier] == getID(scout.value)) {
                            // Only eat heads if the params specifies this
                            if (params.eatHeads) pendingNodes.push(scout.value);
                            //else break;
                        } else {
                            pendingNodes.push(scout.value);
                        }
                    } else {
                        break;
                    }
                }
            }
            node = newNodes.pop();
            if (node != null) newNodesByID[getID(node)] = null;
        }

        // Update cells in the eaten region
        for (group in eatenNodeGroups) {
            var nodesEaten = false;
            for (node in group) {
                if (node != null && node[occupier_] != currentPlayer) {
                    node[occupier_] = currentPlayer;
                    node[freshness_] = maxFreshness;
                    nodesEaten = true;
                }
            }
            if (nodesEaten) maxFreshness++;
        }

        state.global[maxFreshness_] = maxFreshness;

        // Clean up the bodyFirst and head pointers for opponent players
        for (player in eachPlayer()) {
            var playerID:Int = getID(player);
            if (playerID == currentPlayer) continue;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != NULL) {
                var body:Array<AspectSet> = getNode(bodyFirst).listToArray(state.nodes, bodyNext_);
                var revisedBody:Array<AspectSet> = [];
                for (node in body) {
                    if (node[isFilled_] == TRUE && node[occupier_] == playerID) revisedBody.push(node);
                }
                revisedBody.chainByAspect(ident_, bodyNext_, bodyPrev_);
                if (revisedBody.length > 0) player[bodyFirst_] = getID(revisedBody[0]);
                else player[bodyFirst_] = NULL;
            }

            var head:Int = player[head_];
            if (head != NULL) {
                var headNode:AspectSet = getNode(head);
                if (headNode[occupier_] != playerID) player[head_] = NULL;
            }
        }

        // Add the filled eaten nodes to the current player body
        for (node in eatenNodes) {
            if (node != null && node[isFilled_] == TRUE) {
                bodyNode = bodyNode.addSet(node, state.nodes, ident_, bodyNext_, bodyPrev_);
            }
        }
        getPlayer(currentPlayer)[bodyFirst_] = getID(bodyNode);
        signalChange();
    }

    function getBody(playerID:Int):Array<AspectSet> {
        var bodyNode:AspectSet = getNode(getPlayer(playerID)[bodyFirst_]);
        return bodyNode.listToArray(state.nodes, bodyNext_);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me[isFilled_] == FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function isFresh(node:AspectSet):Bool {
        return node[freshness_] != NULL;
    }

    function directionsFor(ortho:Bool):Iterator<Int> {
        return ortho ? GridUtils.orthoDirections() : GridUtils.allDirections();
    }
}

