package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class EatCellsRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var playerReqs:AspectRequirements;
    static var stateReqs:AspectRequirements;
    static var option:Option = new Option();

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var head_:AspectPtr;

    var recursive:Bool;

    private var cfg:EatCellsConfig;

    public function new(cfg:EatCellsConfig):Void {
        super();
        this.cfg = cfg;

        if (nodeReqs == null)  nodeReqs = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
        ];

        if (playerReqs == null) playerReqs = [
            BodyAspect.HEAD,
        ];

        if (stateReqs == null) stateReqs = [
            PlyAspect.CURRENT_PLAYER,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];

        recursive = cfg.recursive;
    }

    override public function listStateAspectRequirements():AspectRequirements { return stateReqs; }
    override public function listPlayerAspectRequirements():AspectRequirements { return playerReqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return nodeReqs; }
    override public function getOptions():Array<Option> { return [option]; }

    override public function chooseOption(choice:Option):Void {
        if (choice == option) {

            // perform eat operation on state

            // Find all fresh nodes
            // hint: they're body nodes

            var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
            var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

            var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
            var head:Int = history.get(state.players[currentPlayer].at(head_));

            var playerHead:BoardNode = state.nodes[head];

            var nodes:Array<BoardNode> = playerHead.getGraph(true, isLivingBodyNeighbor);
            nodes = nodes.filter(isFresh).array();

            var newNodes:Array<BoardNode> = nodes.copy();

            var node:BoardNode = newNodes.pop();
            while (node != null) {
                for (direction in GridUtils.allDirections()) {
                    var pendingNodes:Array<BoardNode> = [];
                    for (scout in node.walk(direction)) {
                        if (scout == node) continue;
                        if (history.get(scout.value.at(isFilled_)) > 0) {
                            if (history.get(scout.value.at(occupier_)) == currentPlayer) {
                                for (pendingNode in pendingNodes) {
                                    eatCell(pendingNode.value, currentPlayer);
                                    if (recursive) newNodes.push(pendingNode);
                                    nodes.push(pendingNode);
                                }
                                break;
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


        }
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
}

