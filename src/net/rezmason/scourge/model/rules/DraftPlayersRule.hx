package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;

typedef PlayerConfig = {
    public var numPlayers:Int;
    public var history:StateHistory;
}

class DraftPlayersRule extends Rule {

    private var cfg:PlayerConfig;

    public function new(cfg:PlayerConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        if (cfg.numPlayers < 1) throw "Invalid number of players in player config.";
        for (ike in 0...cfg.numPlayers) state.players.push(createAspectSet(plan.playerAspectTemplate, cfg.history));
    }

    inline function createAspectSet(template:AspectSet, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) {
            //aspects.push(history.alloc(val)); // H
            aspects.push(val);
        }
        return aspects;
    }
}
