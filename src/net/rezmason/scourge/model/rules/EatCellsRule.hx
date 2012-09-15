package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

typedef EatCellsConfig = {
    public var recursive:Bool;
    public var eatHeads:Bool;
    public var takeBodiesFromHeads:Bool;
}

class EatCellsRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var maxFreshness_:AspectPtr;
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;
    var bodyPrev_:AspectPtr;

    private var cfg:EatCellsConfig;

    public function new(cfg:EatCellsConfig):Void {
        super();
        this.cfg = cfg;

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
            FreshnessAspect.MAX_FRESHNESS,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
            BodyAspect.BODY_FIRST,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
            BodyAspect.BODY_NEXT,
            BodyAspect.BODY_PREV,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        maxFreshness_ = state.stateAspectLookup[FreshnessAspect.MAX_FRESHNESS.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        bodyFirst_ = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        bodyPrev_ = state.nodeAspectLookup[BodyAspect.BODY_PREV.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        // Find all fresh body nodes of the current player

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];
        var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];
        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        var headIndices:Array<Int> = [];
        for (player in state.players) headIndices.push(player.at(head_));

        var nodes:Array<BoardNode> = bodyNode.boardListToArray(state, bodyNext_);
        nodes = nodes.filter(isFresh).array();

        var newNodes:Array<BoardNode> = nodes.copy();
        var eatenNodes:Array<BoardNode> = [];

        var node:BoardNode = newNodes.pop();
        while (node != null) {
            for (direction in GridUtils.allDirections()) {
                var pendingNodes:Array<BoardNode> = [];
                for (scout in node.walk(direction)) {
                    if (scout == node) continue;
                    if (scout.value.at(isFilled_) > 0) {
                        var scoutOccupier:Int = scout.value.at(occupier_);
                        if (scoutOccupier == currentPlayer || eatenNodes.has(scout)) {
                            for (pendingNode in pendingNodes) {
                                var playerIndex:Int = headIndices.indexOf(pendingNode.id);
                                if (playerIndex != -1) {
                                    if (cfg.takeBodiesFromHeads) pendingNodes.absorb(getBody(playerIndex));
                                } else {
                                    if (cfg.recursive && !newNodes.has(pendingNode)) newNodes.push(pendingNode);
                                }
                                eatenNodes.push(pendingNode);
                            }
                            break;
                        } else if (headIndices[scoutOccupier] == scout.id) {
                            if (cfg.eatHeads) pendingNodes.push(scout);
                            else break;
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

        for (node in eatenNodes) bodyNode = eatCell(node, currentPlayer, maxFreshness++, bodyNode);

        state.players[currentPlayer].mod(bodyFirst_, bodyNode.id);
        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    function getBody(player:Int):Array<BoardNode> {
        var bodyNode:BoardNode = state.nodes[state.players[player].at(bodyFirst_)];
        return bodyNode.boardListToArray(state, bodyNext_);
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
        return bodyNode.addNode(node, state, bodyNext_, bodyPrev_);
    }
}

