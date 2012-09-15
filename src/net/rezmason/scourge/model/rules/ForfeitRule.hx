package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class ForfeitRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;
    var bodyPrev_:AspectPtr;

    public function new():Void {
        super();

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
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
        occupier_ = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ =   plan.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        bodyFirst_ = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        bodyPrev_ = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var player:AspectSet = state.players[currentPlayer];
        var bodyNode:BoardNode = state.nodes[player.at(bodyFirst_)];

        for (node in bodyNode.boardListToArray(state.nodes, bodyNext_)) killCell(node);
        player.mod(bodyFirst_, Aspect.NULL);
        player.mod(head_, Aspect.NULL);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me.at(isFilled_) == Aspect.FALSE) return false;
        return me.at(occupier_) == you.at(occupier_);
    }

    function killCell(node:BoardNode):Void {
        node.value.mod(isFilled_, Aspect.FALSE);
        node.value.mod(occupier_, Aspect.NULL);
        node.removeNode(state.nodes, bodyNext_, bodyPrev_);
    }
}

