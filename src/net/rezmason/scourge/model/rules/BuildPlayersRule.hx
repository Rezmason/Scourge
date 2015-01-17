package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.RopesRule;

typedef BuildPlayersConfig = { public var numPlayers:Int; }

class BuildPlayersRule extends RopesRule<BuildPlayersConfig> {
    override private function _prime():Void {
        if (config.numPlayers < 1) throw 'Invalid number of players in player config.';
        for (ike in 0...config.numPlayers) addPlayer();
    }
}
