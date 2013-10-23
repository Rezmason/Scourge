package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.QUIT_ACTION;

class ReplaySmarts extends Smarts {

    private var log:Array<GameEvent>;

    public function new(log:Array<GameEvent>):Void {
        super();
        if (log == null) log = [];
        this.log = log;
    }

    override public function choose(game:Game):GameEventType {
        var moves = game.getMoves();
        // trace(moves[1].length);
        var type:GameEventType = log.shift().type;

        var params = Type.enumParameters(type);
        if (moves[params[0]].length < params[1] + 1) {
            // trace('Move failure: $type < ${moves[params[0]].length}');
            type = null;
        }

        if (type == null) type = PlayerAction(actionIndicesByAction[QUIT_ACTION], 0);
        // trace(type);
        return type;
    }
}
