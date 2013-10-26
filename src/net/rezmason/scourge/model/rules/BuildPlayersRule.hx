package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.ropes.Types;

using net.rezmason.utils.Pointers;

typedef BuildPlayersConfig = {
    public var buildCfg:BuildConfig;
    public var numPlayers:Int;
}

class BuildPlayersRule extends Rule {


    var playerAspectTemplate:AspectSet;
    var cfg:BuildPlayersConfig;

    public function new(cfg:BuildPlayersConfig):Void {
        super();
        demiurgic = true;
        this.cfg = cfg;
    }

    override private function _prime():Void {
        if (cfg.numPlayers < 1) throw 'Invalid number of players in player config.';
        playerAspectTemplate = plan.playerAspectTemplate.copy();
        for (ike in 0...cfg.numPlayers) makePlayer();
    }

    inline function makePlayer():AspectSet {
        var player:AspectSet = playerAspectTemplate.copy();
        player[ident_] = numPlayers();
        state.players.push(player);
        var histNode:AspectSet = playerAspectTemplate.map(cfg.buildCfg.history.alloc);
        cfg.buildCfg.historyState.players.push(histNode);

        return player;
    }
}
