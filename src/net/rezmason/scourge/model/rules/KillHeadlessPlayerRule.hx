package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessPlayerRule extends Rule {

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
        head_ = playerPtr(BodyAspect.HEAD);

        bodyFirst_ = playerPtr(BodyAspect.BODY_FIRST);
        bodyNext_ = nodePtr(BodyAspect.BODY_NEXT);
        bodyPrev_ = nodePtr(BodyAspect.BODY_PREV);
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        for (playerIndex in 0...state.players.length) {
            var player:AspectSet = state.players[playerIndex];

            var head:Int = player.at(head_);
            var bodyFirst:Int = player.at(bodyFirst_);

            if (head != Aspect.NULL) {
                var playerHead:BoardNode = state.nodes[head];
                if (playerHead.value.at(occupier_) != playerIndex || playerHead.value.at(isFilled_) == Aspect.FALSE) {
                    player.mod(head_, Aspect.NULL);
                    for (node in state.nodes[bodyFirst].iterate(state.nodes, bodyNext_)) node.removeNode(state.nodes, bodyNext_, bodyPrev_);
                    player.mod(bodyFirst_, Aspect.NULL);
                }
            }

        }
    }
}

