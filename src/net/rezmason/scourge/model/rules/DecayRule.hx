package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class DecayRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_:AspectPtr;
    @node(BodyAspect.BODY_PREV) var bodyPrev_:AspectPtr;
    @node(BodyAspect.NODE_ID) var nodeID_:AspectPtr;
    @node(OwnershipAspect.IS_FILLED) var isFilled_:AspectPtr;
    @node(OwnershipAspect.OCCUPIER) var occupier_:AspectPtr;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_:AspectPtr;
    @player(BodyAspect.TOTAL_AREA) var totalArea_:AspectPtr;
    @player(BodyAspect.HEAD) var head_:AspectPtr;

    public function new():Void {
        super();
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);
        // perform kill operation on state

        var heads:Array<BoardNode> = [];
        for (player in state.players) {
            var headIndex:Int = player.at(head_);
            if (headIndex != Aspect.NULL) heads.push(state.nodes[headIndex]);
        }
        var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

        for (player in state.players) {

            var totalArea:Int = 0;

            // Removing nodes is not something to do haphazardly - what if you remove the first one?

            var bodyFirst:Int = player.at(bodyFirst_);
            if (bodyFirst != Aspect.NULL) {
                for (node in state.nodes[bodyFirst].iterate(state.nodes, bodyNext_)) {
                    if (!livingBodyNeighbors.has(node)) bodyFirst = killCell(node, bodyFirst);
                    else totalArea++;
                }
            }

            player.mod(bodyFirst_, bodyFirst);
            player.mod(totalArea_, totalArea);
        }
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me.at(isFilled_) == Aspect.FALSE) return false;
        return me.at(occupier_) == you.at(occupier_);
    }

    function killCell(node:BoardNode, firstIndex:Int):Int {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);

        var nextNode:BoardNode = node.removeNode(state.nodes, bodyNext_, bodyPrev_);
        if (firstIndex == node.value.at(nodeID_)) firstIndex = nextNode == null ? Aspect.NULL : nextNode.value.at(nodeID_);
        return firstIndex;
    }
}

