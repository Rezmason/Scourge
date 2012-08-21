package net.rezmason.scourge.model.evaluators;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.ModelTypes;
using net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class TestEvaluator extends Evaluator {

    override public function evaluate():Int {
        var ply:PlyAspect = cast state.aspects.get(PlyAspect.id);
        var currentPlayer:Int = historyArray[ply.currentPlayer];
        return state.nodes[state.players[currentPlayer].head].getGraph(true, myContiguous).length;
    }

    function myContiguous(aspects:Aspects, connection:Aspects):Bool {
        var ply:PlyAspect = cast state.aspects.get(PlyAspect.id);
        var aspect:OwnershipAspect = cast aspects.get(OwnershipAspect.id);
        return historyArray[aspect.occupier] == historyArray[ply.currentPlayer] &&
                historyArray[aspect.isFilled] == 1;
    }

}
