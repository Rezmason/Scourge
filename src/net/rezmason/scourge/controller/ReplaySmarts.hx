package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.QUIT_ACTION;

class ReplaySmarts extends Smarts {

    private var log:Array<GameEvent>;

    public function new(log:Array<GameEvent>):Void {
        super();
        if (log == null) log = [];
        this.log = log;
    }

    override public function choose():GameEventType {
        // trace(moves[1].length);
        var type:GameEventType = log.shift().type;
        var params = Type.enumParameters(type);
        var actionIndex:Int = params[0];
        var moveIndex:Int = params[1];
        var moves:Array<Move> = game.getMovesForAction(actionIndex);
        
        if (moves.length < moveIndex + 1) {
            // trace('Move failure: $type < ${moves.length}');
            type = null;
        }

        if (type == null) type = PlayerAction(SubmitMove(actionIndicesByAction[QUIT_ACTION], 0));
        // trace(type);
        return type;
    }
}
