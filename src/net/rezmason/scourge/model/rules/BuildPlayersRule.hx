package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.rules.BuildRule;

typedef BuildPlayersConfig = {>BuildConfig,
    public var numPlayers:Int;
}

class BuildPlayersRule extends BuildRule {

    private var cfg:BuildPlayersConfig;

    public function new(cfg:BuildPlayersConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        if (cfg.numPlayers < 1) throw "Invalid number of players in player config.";

        var historyState:State = cfg.historyState;

        for (ike in 0...cfg.numPlayers) {
            state.players.push(buildAspectSet(plan.playerAspectTemplate));
            historyState.players.push(buildHistAspectSet(plan.playerAspectTemplate, cfg.history));
        }
    }
}
