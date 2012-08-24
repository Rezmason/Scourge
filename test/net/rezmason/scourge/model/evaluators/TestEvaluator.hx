package net.rezmason.scourge.model.evaluators;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.ModelTypes;
using net.rezmason.scourge.model.aspects.BodyAspect;
using net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class TestEvaluator extends Evaluator {

    override public function evaluate(state:State):Int {

        var history:StateHistory = state.history;

        var currentPlayer_:Int = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects[currentPlayer_]);

        var head_:Int = state.playerAspectLookup[BodyAspect.HEAD.id];
        var head:Int = history.get(state.players[currentPlayer][head_]);

        var playerHead:BoardNode = state.nodes[head];

        var occupier_:Int = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:Int = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        function myContiguous(me:Aspects, you:Aspects):Bool {
            var occupier:Int = history.get(me[occupier_]);
            var isFilled:Int = history.get(me[isFilled_]);
            return occupier == currentPlayer && isFilled == 1;
        }

        return playerHead.getGraph(true, myContiguous).length;
    }

}
