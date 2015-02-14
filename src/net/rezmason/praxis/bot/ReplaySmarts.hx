package net.rezmason.praxis.bot;

import net.rezmason.praxis.PraxisTypes.Move;
import net.rezmason.praxis.bot.Smarts;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.GameEvent;

class ReplaySmarts extends Smarts {

    private var log:Array<GameEvent>;

    public function new(log:Array<GameEvent>):Void {
        super();
        if (log == null) log = [];
        this.log = log;
    }

    override public function choose():GameEvent {
        var event:GameEvent = null;
        var moveActionID:String = null;
        var moveIndex:Int = 0;

        while (moveActionID == null) {
            event = log.shift();
            switch (event) {
                case RelayMove(_, actionID, index): 
                    moveActionID = actionID;
                    moveIndex = index;
                case _:
            }
        }

        var moves:Array<Move> = game.getMovesForAction(moveActionID);
        
        if (moves.length < moveIndex + 1) {
            trace('Move failure: $event < ${moves.length}');
            event = null;
        }

        if (event == null) event = SubmitMove(game.revision, 'forfeit', 0);
        trace(event);
        return event;
    }
}
