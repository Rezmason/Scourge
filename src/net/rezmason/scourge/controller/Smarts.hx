package net.rezmason.scourge.controller;

import net.rezmason.ropes.Types.Move;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;

using Lambda;

class Smarts {

    private static var ACTIONS:Array<String> = [DROP_ACTION, SWAP_ACTION, BITE_ACTION, QUIT_ACTION];

    private var actionIndices:Array<Int>;
    private var moves:Array<Array<Move>>;

    public function new():Void {

    }

    public function init(game:Game):Void actionIndices = ACTIONS.map(game.actionIDs.indexOf);

    public function choose(game:Game):GameEventType {
        moves = game.getMoves();
        var type:GameEventType = null;
        for (actionIndex in actionIndices) if ((type = attempt(actionIndex)) != null) break;
        return type;
    }

    public function attempt(actionIndex:Int):GameEventType {
        var type:GameEventType = null;
        var possible:Bool = actionIndex != -1 && moves[actionIndex].length > 0;
        if (possible) type = PlayerAction(actionIndex, Std.random(moves[actionIndex].length));
        return type;
    }
}
