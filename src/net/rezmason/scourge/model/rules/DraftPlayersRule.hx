package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.TestAspect;

class DraftPlayersRule extends Rule {

    static var reqs:AspectRequirements;

    private var cfg:PlayerConfig;

    public function new(cfg:PlayerConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init(state:State):Void {
        super.init(state);
        if (cfg.numPlayers < 1) throw "Invalid number of players in player config.";
        for (ike in 0...cfg.numPlayers) state.players.push(createAspectSet(state.playerAspectTemplate, history));
    }

    inline function createAspectSet(template:AspectTemplate, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(history.alloc(val));
        return aspects;
    }
}
