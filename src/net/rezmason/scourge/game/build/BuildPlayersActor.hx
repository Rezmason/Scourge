package net.rezmason.scourge.game.build;

import net.rezmason.praxis.rule.Actor;

class BuildPlayersActor extends Actor<BuildPlayersParams> {
    override private function _prime():Void {
        if (params.numPlayers < 1) throw 'Invalid number of players in player params.';
        for (ike in 0...params.numPlayers) addPlayer();
    }
}
