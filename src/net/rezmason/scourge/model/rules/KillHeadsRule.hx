package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class KillHeadsRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;

    public function new():Void {
        super();

        playerAspectRequirements = [
            BodyAspect.HEAD,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        for (playerIndex in 0...state.players.length) {
            var player:AspectSet = state.players[playerIndex];

            var me:AspectSet = state.nodes[history.get(player.at(head_))].value;
            if (history.get(me.at(occupier_)) != playerIndex || history.get(me.at(isFilled_)) == 0) {
                history.set(player.at(head_), -1);
            }
        }
    }
}

