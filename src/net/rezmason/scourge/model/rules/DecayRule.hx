package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

typedef DecayConfig = {
    var orthoOnly:Bool;
}

class DecayRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(BodyAspect.NODE_ID) var nodeID_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(BodyAspect.HEAD) var head_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    private var cfg:DecayConfig;

    public function new(cfg:DecayConfig):Void {
        super();
        this.cfg = cfg;
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        // Grab all the player heads

        var heads:Array<BoardNode> = [];
        for (player in state.players) {
            var headIndex:Int = player.at(head_);
            if (headIndex != Aspect.NULL) heads.push(state.nodes[headIndex]);
        }

        // Use the heads as starting points for a flood fill of connected living cells
        var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(cfg.orthoOnly, isLivingBodyNeighbor);

        // Remove cells from player bodies
        for (player in state.players) {

            var totalArea:Int = 0;

            var bodyFirst:Int = player.at(bodyFirst_);
            if (bodyFirst != Aspect.NULL) {
                for (node in state.nodes[bodyFirst].iterate(state.nodes, bodyNext_)) {
                    if (!livingBodyNeighbors.has(node)) bodyFirst = killCell(node, maxFreshness, bodyFirst);
                    else totalArea++;
                }
            }

            player.mod(bodyFirst_, bodyFirst);
            player.mod(totalArea_, totalArea);
        }

        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me.at(isFilled_) == Aspect.FALSE) return false;
        return me.at(occupier_) == you.at(occupier_);
    }

    function killCell(node:BoardNode, maxFreshness:Int, firstIndex:Int):Int {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);
        node.value.mod(freshness_, maxFreshness);

        var nextNode:BoardNode = node.removeNode(state.nodes, bodyNext_, bodyPrev_);
        if (firstIndex == node.value.at(nodeID_)) {
            firstIndex = (nextNode == null) ? Aspect.NULL : nextNode.value.at(nodeID_);
        }
        return firstIndex;
    }
}

