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

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];

        bodyFirst_ = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        bodyPrev_ = state.nodeAspectLookup[BodyAspect.BODY_PREV.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        for (playerIndex in 0...state.players.length) {
            var player:AspectSet = state.players[playerIndex];

            var head:Int = history.get(player.at(head_));
            var bodyFirst:Int = history.get(player.at(bodyFirst_));

            if (head != Aspect.NULL) {
                var playerHead:BoardNode = state.nodes[head];
                if (history.get(playerHead.value.at(occupier_)) != playerIndex || history.get(playerHead.value.at(isFilled_)) == Aspect.FALSE) {
                    history.set(player.at(head_), Aspect.NULL);
                    for (node in state.nodes[bodyFirst].iterate(state, bodyNext_)) node.removeNode(state, bodyNext_, bodyPrev_);
                    history.set(player.at(bodyFirst_), Aspect.NULL);
                }
            }

        }
    }
}

