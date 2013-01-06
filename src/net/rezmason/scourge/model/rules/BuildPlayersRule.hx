package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;

typedef BuildPlayersConfig = {
    public var buildCfg:BuildConfig;
    public var numPlayers:Int;
}

class BuildPlayersRule extends Rule {

    private var cfg:BuildPlayersConfig;

    public function new(cfg:BuildPlayersConfig):Void {
        super();
        demiurgic = true;
        this.cfg = cfg;
    }

    override private function _prime():Void {

        if (cfg.numPlayers < 1) throw "Invalid number of players in player config.";

        var historyState:State = cfg.buildCfg.historyState;

        for (ike in 0...cfg.numPlayers) {
            state.players.push(buildAspectSet(plan.playerAspectTemplate));
            historyState.players.push(buildHistAspectSet(plan.playerAspectTemplate, cfg.buildCfg.history));
        }
    }
}
