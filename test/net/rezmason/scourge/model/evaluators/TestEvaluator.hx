package net.rezmason.scourge.model.evaluators;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class TestEvaluator extends Evaluator {

    override public function evaluate(state:State):Int {

        var history:StateHistory = state.history;

        var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);
        var currentPlayer:Int = state.aspects[currentPlayer_];

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var head:Int = state.players[currentPlayer][head_];

        var playerHead:BoardLocus = state.nodes[head];

        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onNode(OwnershipAspect.IS_FILLED);

        function myContiguous(me:AspectSet, you:AspectSet):Bool {
            var occupier:Int = me[occupier_];
            var isFilled:Int = me[isFilled_];
            return occupier == currentPlayer && isFilled == 1;
        }

        return playerHead.getGraph(true, myContiguous).length;
    }

}
