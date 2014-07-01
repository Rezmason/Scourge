package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.ropes.AspectUtils;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

typedef DecayConfig = {
    var orthoOnly:Bool;
}

class DecayRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    private var cfg:DecayConfig;

    override public function _init(cfg:Dynamic):Void {
        this.cfg = cfg;
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var maxFreshness:Int = state.globals[maxFreshness_] + 1;

        // Grab all the player heads

        var heads:Array<BoardLocus> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != Aspect.NULL && getNode(headIndex)[occupier_] == getID(player)) {
                heads.push(getLocus(headIndex));
            }
        }

        // Use the heads as starting points for a flood fill of connected living cells
        var livingBodyNeighbors:Array<BoardLocus> = heads.expandGraph(cfg.orthoOnly, isLivingBodyNeighbor);

        // Remove cells from player bodies
        for (player in eachPlayer()) {

            var totalArea:Int = 0;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != Aspect.NULL) {
                for (node in getNode(bodyFirst).iterate(state.nodes, bodyNext_)) {
                    if (livingBodyNeighbors[getID(node)] == null) {
                        bodyFirst = killCell(node, maxFreshness, bodyFirst);
                        maxFreshness++;
                    } else {
                        totalArea++;
                    }
                }
            }

            player[bodyFirst_] = bodyFirst;
            player[totalArea_] = totalArea;
        }

        state.globals[maxFreshness_] = maxFreshness;
        signalEvent();
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me[isFilled_] == Aspect.FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function killCell(node:AspectSet, freshness:Int, firstIndex:Int):Int {
        node[isFilled_] = Aspect.FALSE;
        node[occupier_] = Aspect.NULL;
        node[freshness_] = freshness;

        var nextNode:AspectSet = node.removeSet(state.nodes, bodyNext_, bodyPrev_);
        if (firstIndex == getID(node)) {
            firstIndex = (nextNode == null) ? Aspect.NULL : getID(nextNode);
        }
        return firstIndex;
    }
}

