package net.rezmason.scourge.model.evaluators;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.ModelTypes;
using net.rezmason.scourge.model.aspects.BodyAspect;
using net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class TestEvaluator extends Evaluator {

    override public function evaluate(state:State):Int {

        var history:History<Int> = state.history;

        var currentPlayer_:Int = state.nodeAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects[currentPlayer_]);

        var head_:Int = state.nodeAspectLookup[BodyAspect.HEAD.id];
        var head:Int = history.get(state.players[currentPlayer][head_]);

        if (head == -1) return -1;

        var playerHead:BoardNode = state.nodes[history.get(head)];

        var occupier_:Int = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:Int = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        function myContiguous(me:Aspects, you:Aspects):Bool {
            var occupier:Int = history.get(me[occupier_]);
            var isFilled:Int = history.get(me[isFilled_]);
            return history.get(occupier) == currentPlayer && history.get(isFilled) == 1;
        }

        return playerHead.getGraph(true, myContiguous).length;
    }

}
