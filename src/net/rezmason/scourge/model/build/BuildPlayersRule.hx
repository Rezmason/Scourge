package net.rezmason.scourge.model.build;

import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.model.TempParams;

class BuildPlayersRule extends BaseRule<FullBuildPlayersParams> {
    override private function _prime():Void {
        if (params.numPlayers < 1) throw 'Invalid number of players in player params.';
        for (ike in 0...params.numPlayers) addPlayer();
    }
}
