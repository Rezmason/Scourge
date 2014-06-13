package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class EndTurnRule extends Rule {

    @player(BodyAspect.HEAD) var head_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    public function new():Void {
        super();
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        // Get current player

        var currentPlayer:Int = state.aspects[currentPlayer_];

        // Find the next living player
        var startPlayerIndex:Int = (currentPlayer + 1) % numPlayers();
        var playerID:Int = startPlayerIndex;
        while (getPlayer(playerID)[head_] == Aspect.NULL) {
            playerID = (playerID + 1) % numPlayers();
            if (playerID == startPlayerIndex) throw 'No players have heads!';
        }

        state.aspects[currentPlayer_] = playerID;
        signalEvent();
    }
}

