package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.ropes.RopesTypes;

using net.rezmason.utils.Pointers;

typedef BuildPlayersConfig = {
    public var numPlayers:Int;
}

class BuildPlayersRule extends Rule {

    var cfg:BuildPlayersConfig;

    override public function _init(cfg:Dynamic):Void { this.cfg = cfg; }

    override private function _prime():Void {
        if (cfg.numPlayers < 1) throw 'Invalid number of players in player config.';
        for (ike in 0...cfg.numPlayers) makePlayer();
    }

    inline function makePlayer():AspectSet {
        var player:AspectSet = buildPlayer();
        player[ident_] = numPlayers();
        state.players.push(player);
        
        allocHistPlayer();

        return player;
    }
}
