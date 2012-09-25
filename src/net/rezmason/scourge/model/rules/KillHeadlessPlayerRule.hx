package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessPlayerRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_:AspectPtr;
    @node(BodyAspect.BODY_PREV) var bodyPrev_:AspectPtr;
    @node(OwnershipAspect.IS_FILLED) var isFilled_:AspectPtr;
    @node(OwnershipAspect.OCCUPIER) var occupier_:AspectPtr;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_:AspectPtr;
    @player(BodyAspect.HEAD) var head_:AspectPtr;

    public function new():Void {
        super();
        options.push({optionID:0});
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

