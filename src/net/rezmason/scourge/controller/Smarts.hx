package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;

class Smarts {

    private var actionIndicesByAction:Map<String, Int>;
    private var game:Game;
    private var config:ScourgeConfig;
    private var id:Int;
    private var random:Void->Float;

    public function new():Void {}

    public function init(game:Game, config:ScourgeConfig, id:Int, random:Void->Float):Void {
        actionIndicesByAction = new Map();
        for (ike in 0...game.actionIDs.length) actionIndicesByAction[game.actionIDs[ike]] = ike;
        this.game = game;
        this.config = config;
        this.id = id;
        this.random = random;
    }

    public function choose():GameEventType {
        throw "Override this.";
        return null;
    }

    /*inline*/ function randRange(range:Float):Float return random() * range;
    /*inline*/ function randIntRange(range:Int):Int return Std.int(randRange(range));
}
