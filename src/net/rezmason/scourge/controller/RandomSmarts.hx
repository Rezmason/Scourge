package net.rezmason.scourge.controller;

import Std.random;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;

using Lambda;

class RandomSmarts extends Smarts {

    private static var PRIORITIZED_ACTIONS:Array<String> = [DROP_ACTION, SWAP_ACTION, BITE_ACTION, QUIT_ACTION];

    private var actionIndices:Array<Int>;
    
    override public function init(game:Game):Void {
        super.init(game);
        actionIndices = PRIORITIZED_ACTIONS.map(function(el) return game.actionIDs.indexOf(el));
    }

    override public function choose(game:Game):GameEventType {
        // trace(moves[1].length);
        var type:GameEventType = null;
        for (actionIndex in actionIndices) {
            if (actionIndex != -1) {
                var moves:Array<Move> = game.getMovesForAction(actionIndex);
                if (moves.length > 0) {
                    type = PlayerAction(SubmitMove(actionIndex, random(moves.length)));
                    // type = PlayerAction(SubmitMove(actionIndex, 0));
                    break;
                }
            }
        }
        // trace(type);
        return type;
    }
}
