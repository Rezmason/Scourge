package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.Types;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

typedef EatCellsConfig = {
    public var recursive:Bool;
    public var eatHeads:Bool;
    public var takeBodiesFromHeads:Bool;
    public var orthoOnly:Bool;
}

class EatCellsRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(IdentityAspect.NODE_ID) var nodeID_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(IdentityAspect.PLAYER_ID) var playerID_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var cfg:EatCellsConfig;

    public function new(cfg:EatCellsConfig):Void {
        super();
        this.cfg = cfg;
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var currentPlayer:Int = state.aspects[currentPlayer_];
        var head:Int = getPlayer(currentPlayer)[head_];
        var playerHead:BoardNode = getNode(head);
        var bodyNode:BoardNode = getNode(getPlayer(currentPlayer)[bodyFirst_]);
        var maxFreshness:Int = state.aspects[maxFreshness_] + 1;

        // List all the players' heads

        var headIndices:Array<Int> = [];
        for (player in eachPlayer()) headIndices.push(player[head_]);

        // Find all fresh body nodes of the current player

        var nodes:Array<BoardNode> = bodyNode.boardListToArray(state.nodes, bodyNext_).filter(isFresh).array();

        var newNodes:List<BoardNode> = nodes.list();
        var eatenNodes:Array<BoardNode> = [];

        // We search space for uninterrupted regions of player cells that begin and end
        // with cells of the current player. We propagate these searches from cells
        // that have been freshly eaten, starting with the current player's fresh nodes

        var node:BoardNode = newNodes.pop();
        while (node != null) {
            // search in all directions
            for (direction in directionsFor(cfg.orthoOnly)) {
                var pendingNodes:Array<BoardNode> = [];
                for (scout in node.walk(direction)) {
                    if (scout == node) continue; // starting node
                    if (scout.value[isFilled_] > 0) {
                        var scoutOccupier:Int = scout.value[occupier_];
                        if (scoutOccupier == currentPlayer || eatenNodes.has(scout)) {
                            // Add nodes to the eaten region
                            for (pendingNode in pendingNodes) {
                                var playerID:Int = headIndices.indexOf(pendingNode.value[nodeID_]);
                                if (playerID != -1 && cfg.takeBodiesFromHeads) pendingNodes.absorb(getBody(playerID)); // body-from-head eating
                                else if (cfg.recursive && !newNodes.has(pendingNode)) newNodes.add(pendingNode); // recursive eating

                                eatenNodes.push(pendingNode);
                            }
                            break;
                        } else if (headIndices[scoutOccupier] == scout.value[nodeID_]) {
                            // Only eat heads if the config specifies this
                            if (cfg.eatHeads) pendingNodes.push(scout);
                            //else break;
                        } else {
                            pendingNodes.push(scout);
                        }
                    } else {
                        break;
                    }
                }
            }
            node = newNodes.pop();
        }

        // Update cell in the eaten region
        for (node in eatenNodes) bodyNode = eatCell(node, currentPlayer, maxFreshness++, bodyNode);

        getPlayer(currentPlayer)[bodyFirst_] = bodyNode.value[nodeID_];
        state.aspects[maxFreshness_] = maxFreshness;

        // Clean up the bodyFirst and head pointers for opponent players
        for (player in eachPlayer()) {
            var playerID:Int = player[playerID_];
            if (playerID == currentPlayer) continue;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != Aspect.NULL) {
                bodyNode = getNode(bodyFirst);
                if (bodyNode.value[occupier_] != playerID) player[bodyFirst_] = Aspect.NULL;
            }

            var head:Int = player[head_];
            if (head != Aspect.NULL) {
                var headNode:BoardNode = getNode(head);
                if (headNode.value[occupier_] != playerID) player[head_] = Aspect.NULL;
            }
        }
    }

    function getBody(playerID:Int):Array<BoardNode> {
        var bodyNode:BoardNode = getNode(getPlayer(playerID)[bodyFirst_]);
        return bodyNode.boardListToArray(state.nodes, bodyNext_);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me[isFilled_] == Aspect.FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function isFresh(node:BoardNode):Bool {
        return node.value[freshness_] > 0;
    }

    function eatCell(node:BoardNode, currentPlayer:Int, maxFreshness:Int, bodyNode:BoardNode):BoardNode {
        node.value[occupier_] = currentPlayer;
        node.value[freshness_] = maxFreshness;
        return bodyNode.addNode(node, state.nodes, nodeID_, bodyNext_, bodyPrev_);
    }

    function directionsFor(ortho:Bool):Iterator<Int> {
        return ortho ? GridUtils.orthoDirections() : GridUtils.allDirections();
    }
}

