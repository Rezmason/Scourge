package net.rezmason.scourge.model.meta;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.aspect.PlyAspect;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.body.BodyAspect;

class EndTurnRule extends RopesRule<Void> {

    @player(BodyAspect.HEAD) var head_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _chooseMove(choice:Int):Void {

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

