package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.ropes.Game;
import net.rezmason.ropes.GameEvent;

class ReplaySmarts extends Smarts {

    private var log:Array<GameEvent>;

    public function new(log:Array<GameEvent>):Void {
        super();
        if (log == null) log = [];
        this.log = log;
    }

    override public function choose():GameEvent {
        
        var found:Bool = false;
        var event:GameEvent = null;

        while (!found) {
            event = log.shift();
            switch (event) {
                case SubmitMove(_, _, _): found = true;
                case _:
            }
        }

        var params = Type.enumParameters(event);
        var actionID:String = params[0];
        var moveIndex:Int = params[1];
        var moves:Array<Move> = game.getMovesForAction(actionID);
        
        if (moves.length < moveIndex + 1) {
            // trace('Move failure: $event < ${moves.length}');
            event = null;
        }

        if (event == null) event = SubmitMove(game.revision, 'forfeit', 0);
        // trace(event);
        return event;
    }
}
