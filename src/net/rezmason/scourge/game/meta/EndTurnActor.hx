package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.body.BodyAspect;

class EndTurnActor extends Actor<Dynamic> {

    @player(BodyAspect.HEAD) var head_;
    @global(PlyAspect.CURRENT_PLAYER, true) var currentPlayer_;

    override private function _chooseMove(_):Void {

        // Get current player

        var currentPlayer:Int = state.global[currentPlayer_];

        // Find the next living player
        var startPlayerIndex:Int = (currentPlayer + 1) % numPlayers();
        var playerID:Int = startPlayerIndex;
        while (getPlayer(playerID)[head_] == NULL) {
            playerID = (playerID + 1) % numPlayers();
            if (playerID == startPlayerIndex) throw 'No players have heads!';
        }

        state.global[currentPlayer_] = playerID;
        signalChange();
    }
}

