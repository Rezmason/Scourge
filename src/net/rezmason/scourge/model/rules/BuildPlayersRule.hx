package net.rezmason.scourge.model.rules;

typedef BuildPlayersConfig = {>BuildConfig,
    public var numPlayers:Int;
}

class BuildPlayersRule extends Rule {

    private var cfg:BuildPlayersConfig;

    public function new(cfg:BuildPlayersConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init():Void {

        if (cfg.numPlayers < 1) throw "Invalid number of players in player config.";

        var historyState:State = cfg.historyState;

        for (ike in 0...cfg.numPlayers) {
            state.players.push(buildAspectSet(plan.playerAspectTemplate));
            historyState.players.push(buildHistAspectSet(plan.playerAspectTemplate, cfg.history));
        }
    }
}
