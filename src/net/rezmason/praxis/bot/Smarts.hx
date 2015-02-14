package net.rezmason.praxis.bot;

import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.config.GameConfig;

class Smarts extends Reckoner {

    private var actionIndicesByAction:Map<String, Int>;
    private var game:Game;
    private var config:GameConfig<Dynamic, Dynamic>;
    private var id:Int;
    private var random:Void->Float;

    public function init(game:Game, config:GameConfig<Dynamic, Dynamic>, id:Int, random:Void->Float):Void {
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
