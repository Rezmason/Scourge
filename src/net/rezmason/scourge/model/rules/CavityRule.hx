package net.rezmason.scourge.model.rules;

//import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class CavityRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.NODE_ID) var nodeID_;
    @node(BodyAspect.CAVITY_NEXT) var cavityNext_;
    @node(BodyAspect.CAVITY_PREV) var cavityPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.CAVITY_FIRST) var cavityFirst_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    var remainingNodes:Int;

    public function new():Void {
        super();
        options.push({optionID:0});
    }

    override public function update():Void {

    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        for (ike in 0...state.players.length) {

            var player:AspectSet = state.players[ike];

            // Destroy existing cavity list
            var cavityFirst:Int = player.at(cavityFirst_);
            var oldCavitySet:Array<BoardNode> = [];
            if (cavityFirst != Aspect.NULL) {
                oldCavitySet = state.nodes[cavityFirst].boardListToArray(state.nodes, bodyNext_);
                for (node in oldCavitySet) clearCavityCell(node);
            }
            player.mod(cavityFirst_, Aspect.NULL);

            // Now for the fun part! Find all the cavity nodes.

            var body:Array<BoardNode> = state.nodes[player.at(bodyFirst_)].boardListToArray(state.nodes, bodyNext_);
            var head:BoardNode = state.nodes[player.at(head_)];

            remainingNodes = body.length - 1;
            var widePerimeter:Array<BoardNode> = head.getGraph(true, callback(isWithinPerimeter, ike));

            widePerimeter.reverse();

            for (jen in 0...widePerimeter.length) {

                var node:BoardNode = widePerimeter[jen];

                var occupier:Int = node.value.at(occupier_);
                var isFilled:Int = node.value.at(isFilled_);
                if (occupier == ike && isFilled == Aspect.TRUE) {
                    continue;
                }

                for (neighbor in node.orthoNeighbors()) {
                    if (neighbor == null || !widePerimeter.has(neighbor)) {
                        widePerimeter[jen] = null;
                        break;
                    }
                }
            }

            var cavityNodes:Array<BoardNode> = widePerimeter.filter(isEmpty).array();

            if (cavityNodes.length > 0) {
                for (node in cavityNodes) {
                    createCavity(ike, node);
                    if (!oldCavitySet.has(node)) node.value.mod(freshness_, maxFreshness);
                }
                cavityNodes.chainByAspect(nodeID_, cavityNext_, cavityPrev_);
                player.mod(cavityFirst_, cavityNodes[0].value.at(nodeID_));
                var totalArea:Int = player.at(totalArea_) + cavityNodes.length;
                player.mod(totalArea_, totalArea);
            }
        }

        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    inline function isEdge(node:BoardNode):Bool {
        return node.neighbors.exists(isOutside);
    }

    inline function isOutside(node:BoardNode):Bool {
        return node.value.at(isFilled_) == Aspect.FALSE;
    }

    inline function isEmpty(node:BoardNode):Bool {
        return node != null && node.value.at(isFilled_) == Aspect.FALSE;
    }

    function isWithinPerimeter(allegiance:Int, me:AspectSet, you:AspectSet):Bool {
        if (remainingNodes <= 0) return false;
        if (me.at(isFilled_) == Aspect.TRUE && me.at(occupier_) == allegiance) remainingNodes--;
        return true;
    }

    inline function createCavity(occupier:Int, node:BoardNode):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, occupier);
    }

    inline function clearCavityCell(node:BoardNode):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);
        node.removeNode(state.nodes, cavityNext_, cavityPrev_);
    }
}
