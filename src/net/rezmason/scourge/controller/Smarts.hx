package net.rezmason.scourge.controller;

import net.rezmason.ropes.Reckoner;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;

class Smarts extends Reckoner {

    private var actionIndicesByAction:Map<String, Int>;
    private var game:Game;
    private var config:ScourgeConfig;
    private var id:Int;
    private var random:Void->Float;

    public function init(game:Game, config:ScourgeConfig, id:Int, random:Void->Float):Void {
        actionIndicesByAction = new Map();
        for (ike in 0...game.actionIDs.length) actionIndicesByAction[game.actionIDs[ike]] = ike;
        this.game = game;
        this.primePointers(game.state, game.plan);
        this.config = config;
        this.id = id;
        this.random = random;
    }

    public function choose():GameEvent {
        throw "Override this.";
        return null;
    }

    inline function randIntRange(range:Int):Int return Std.int(random() * range);
}
