package net.rezmason.scourge.model.evaluators;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class TestEvaluator extends Evaluator {

    override public function evaluate(state:State):Int {

        var history:StateHistory = state.history;

        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var head:Int = history.get(state.players[currentPlayer].at(head_));

        var playerHead:BoardNode = state.nodes[head];

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        function myContiguous(me:AspectSet, you:AspectSet):Bool {
            var occupier:Int = history.get(me.at(occupier_));
            var isFilled:Int = history.get(me.at(isFilled_));
            return occupier == currentPlayer && isFilled == 1;
        }

        return playerHead.getGraph(true, myContiguous).length;
    }

}