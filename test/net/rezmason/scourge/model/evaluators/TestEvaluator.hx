package net.rezmason.scourge.model.evaluators;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.ModelTypes;
using net.rezmason.scourge.model.aspects.OwnershipAspect;

class TestEvaluator extends Evaluator {

    override public function evaluate():Int {
        return state.players[state.currentPlayer].head.getGraph(true, myContiguous).length;
    }

    function myContiguous(aspects:Aspects, connection:Aspects):Bool {
        var aspect:OwnershipAspect = cast aspects.get(OwnershipAspect.id);
        return historyArray[aspect.occupier] == state.currentPlayer &&
                historyArray[aspect.isFilled] == 1;
    }

}
