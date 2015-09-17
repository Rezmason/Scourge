package net.rezmason.scourge.game.build;

import net.rezmason.praxis.rule.Builder;

class PlayerBuilder extends Builder<PlayerBuildParams> {
    override public function prime():Void {
        if (params.numPlayers < 1) throw 'Invalid number of players in player params.';
        for (ike in 0...params.numPlayers) addPlayer();
    }
}
