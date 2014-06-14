package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class EndTurnRule extends Rule {

    @player(BodyAspect.HEAD) var head_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override public function _init(cfg:Dynamic):Void { moves.push({id:0}); }

    override private function _chooseMove(choice:Int):Void {

        // Get current player

        var currentPlayer:Int = state.globals[currentPlayer_];

        // Find the next living player
        var startPlayerIndex:Int = (currentPlayer + 1) % numPlayers();
        var playerID:Int = startPlayerIndex;
        while (getPlayer(playerID)[head_] == Aspect.NULL) {
            playerID = (playerID + 1) % numPlayers();
            if (playerID == startPlayerIndex) throw 'No players have heads!';
        }

        state.globals[currentPlayer_] = playerID;
        signalEvent();
    }
}

