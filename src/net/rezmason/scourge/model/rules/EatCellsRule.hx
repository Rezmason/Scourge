package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.ModelTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
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
    @node(BodyAspect.NODE_ID) var nodeID_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var cfg:EatCellsConfig;

    public function new(cfg:EatCellsConfig):Void {
        super();
        this.cfg = cfg;
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int = 0):Void {
        super.chooseOption(choice);

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];
        var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];
        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        // List all the players' heads

        var headIndices:Array<Int> = [];
        for (player in state.players) headIndices.push(player.at(head_));

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
                    if (scout.value.at(isFilled_) > 0) {
                        var scoutOccupier:Int = scout.value.at(occupier_);
                        if (scoutOccupier == currentPlayer || eatenNodes.has(scout)) {
                            // Add nodes to the eaten region
                            for (pendingNode in pendingNodes) {
                                var playerIndex:Int = headIndices.indexOf(pendingNode.value.at(nodeID_));
                                if (playerIndex != -1 && cfg.takeBodiesFromHeads) pendingNodes.absorb(getBody(playerIndex)); // body-from-head eating
                                else if (cfg.recursive && !newNodes.has(pendingNode)) newNodes.add(pendingNode); // recursive eating

                                eatenNodes.push(pendingNode);
                            }
                            break;
                        } else if (headIndices[scoutOccupier] == scout.value.at(nodeID_)) {
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

        state.players[currentPlayer].mod(bodyFirst_, bodyNode.value.at(nodeID_));
        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    function getBody(player:Int):Array<BoardNode> {
        var bodyNode:BoardNode = state.nodes[state.players[player].at(bodyFirst_)];
        return bodyNode.boardListToArray(state.nodes, bodyNext_);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me.at(isFilled_) == Aspect.FALSE) return false;
        return me.at(occupier_) == you.at(occupier_);
    }

    function isFresh(node:BoardNode):Bool {
        return node.value.at(freshness_) > 0;
    }

    function eatCell(node:BoardNode, currentPlayer:Int, maxFreshness:Int, bodyNode:BoardNode):BoardNode {
        node.value.mod(occupier_, currentPlayer);
        node.value.mod(freshness_, maxFreshness);
        return bodyNode.addNode(node, state.nodes, nodeID_, bodyNext_, bodyPrev_);
    }

    function directionsFor(ortho:Bool):Iterator<Int> {
        return ortho ? GridUtils.orthoDirections() : GridUtils.allDirections();
    }
}

