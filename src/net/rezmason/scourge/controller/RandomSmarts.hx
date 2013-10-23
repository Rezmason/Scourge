package net.rezmason.scourge.controller;

import Std.random;

import net.rezmason.ropes.Types.Move;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;

using Lambda;

class RandomSmarts extends Smarts {

    private static var PRIORITIZED_ACTIONS:Array<String> = [DROP_ACTION, SWAP_ACTION, BITE_ACTION, QUIT_ACTION];

    private var actionIndices:Array<Int>;
    private var moves:Array<Array<Move>>;

    override public function init(game:Game):Void {
        super.init(game);
        actionIndices = PRIORITIZED_ACTIONS.map(game.actionIDs.indexOf);
    }

    override public function choose(game:Game):GameEventType {
        moves = game.getMoves();
        // trace(moves[1].length);
        var type:GameEventType = null;
        for (actionIndex in actionIndices) if ((type = attempt(actionIndex)) != null) break;
        // trace(type);
        return type;
    }

    private function attempt(actionIndex:Int):GameEventType {
        var type:GameEventType = null;
        var possible:Bool = actionIndex != -1 && moves[actionIndex].length > 0;
        if (possible) type = PlayerAction(actionIndex, random(moves[actionIndex].length));
        // if (possible) type = PlayerAction(actionIndex, 0);
        return type;
    }
}
