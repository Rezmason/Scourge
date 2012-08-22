package net.rezmason.scourge.model.evaluators;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.ModelTypes;
using net.rezmason.scourge.model.aspects.BodyAspect;
using net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class TestEvaluator extends Evaluator {

    override public function evaluate(state:State):Int {
        var history:History<Int> = state.history;

        function myContiguous(aspects:Aspects, connection:Aspects):Bool {
            var ply:PlyAspect = cast state.aspects.get(PlyAspect.id);
            var aspect:OwnershipAspect = cast aspects.get(OwnershipAspect.id);
            return history.get(aspect.occupier) == history.get(ply.currentPlayer) &&
                    history.get(aspect.isFilled) == 1;
        }

        var ply:PlyAspect = cast state.aspects.get(PlyAspect.id);
        var currentPlayer:Int = history.get(ply.currentPlayer);
        var body:BodyAspect = cast state.players[currentPlayer].get(BodyAspect.id);
        if (body == null || body.head == -1) return -1;
        var playerHead:BoardNode = state.nodes[history.get(body.head)];
        return playerHead.getGraph(true, myContiguous).length;
    }

}
