package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class DecayRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;
    var bodyPrev_:AspectPtr;

    public function new():Void {
        super();

        playerAspectRequirements = [
            BodyAspect.HEAD,
            BodyAspect.BODY_FIRST,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            BodyAspect.BODY_NEXT,
            BodyAspect.BODY_PREV,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        occupier_ = nodePtr(OwnershipAspect.OCCUPIER);
        isFilled_ = nodePtr(OwnershipAspect.IS_FILLED);
        head_ =   playerPtr(BodyAspect.HEAD);

        bodyFirst_ = playerPtr(BodyAspect.BODY_FIRST);
        bodyNext_ = nodePtr(BodyAspect.BODY_NEXT);
        bodyPrev_ = nodePtr(BodyAspect.BODY_PREV);
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

            // Removing nodes is not something to do haphazardly - what if you remove the first one?

            var bodyFirst:Int = player.at(bodyFirst_);
            if (bodyFirst != Aspect.NULL) {
                for (node in state.nodes[bodyFirst].iterate(state.nodes, bodyNext_)) {
                    if (!livingBodyNeighbors.has(node)) bodyFirst = killCell(node, bodyFirst);
                }
            }
            player.mod(bodyFirst_, bodyFirst);
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
        if (firstIndex == node.id) firstIndex = nextNode == null ? Aspect.NULL : nextNode.id;
        return firstIndex;
    }
}

