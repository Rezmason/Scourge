package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
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
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;

    private var cfg:EatCellsConfig;

    public function new(cfg:EatCellsConfig):Void {
        super();
        this.cfg = cfg;

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        bodyFirst_ = state.nodeAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        // Find all fresh nodes
        // hint: they're body nodes

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        var headIndices:Array<Int> = [];
        for (player in state.players) headIndices.push(history.get(player.at(head_)));

        var nodes:Array<BoardNode> = playerHead.getGraph(true, isLivingBodyNeighbor);
        nodes = nodes.filter(isFresh).array();

        var newNodes:Array<BoardNode> = nodes.copy();
        var eatenNodes:Array<BoardNode> = [];
        var potentiallyDeadNodes:Array<BoardNode> = [];

        var node:BoardNode = newNodes.pop();
        while (node != null) {
            for (direction in GridUtils.allDirections()) {
                var pendingNodes:Array<BoardNode> = [];
                for (scout in node.walk(direction)) {
                    if (scout == node) continue;
                    if (history.get(scout.value.at(isFilled_)) > 0) {
                        var scoutOccupier:Int = history.get(scout.value.at(occupier_));
                        if (scoutOccupier == currentPlayer || eatenNodes.has(scout)) {
                            for (pendingNode in pendingNodes) {
                                if (headIndices.has(pendingNode.id)) {
                                    var enemyBody:Array<BoardNode> = pendingNode.getGraph(true, isLivingBodyNeighbor);
                                    if (cfg.takeBodiesFromHeads) pendingNodes.absorb(enemyBody);
                                    else potentiallyDeadNodes.absorb(enemyBody);
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

        for (node in eatenNodes) eatCell(node.value, currentPlayer);
        for (node in potentiallyDeadNodes) if (history.get(node.value.at(occupier_)) != currentPlayer) killCell(node.value);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me.at(isFilled_)) == 0) return false;
        return history.get(me.at(occupier_)) == history.get(you.at(occupier_));
    }

    function isFresh(node:BoardNode):Bool {
        return history.get(node.value.at(freshness_)) > 0;
    }

    function eatCell(me:AspectSet, currentPlayer:Int):Void {
        history.set(me.at(occupier_), currentPlayer);
        history.set(me.at(freshness_), 1);
    }

    function killCell(me:AspectSet):Void {
        history.set(me.at(isFilled_), 0);
        history.set(me.at(occupier_), -1);
    }
}

