package net.rezmason.scourge.model.build;

import net.rezmason.ropes.RopesRule;

class BuildPlayersRule extends RopesRule<BuildPlayersParams> {
    override private function _prime():Void {
        if (params.numPlayers < 1) throw 'Invalid number of players in player params.';
        for (ike in 0...params.numPlayers) addPlayer();
    }
}
