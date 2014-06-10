package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;

class Smarts {

    private var actionIndicesByAction:Map<String, Int>;
    private var game:Game;
    private var config:ScourgeConfig;
    private var id:Int;

    public function new():Void {}

    public function init(game:Game, config:ScourgeConfig, id:Int):Void {
        actionIndicesByAction = new Map();
        for (ike in 0...game.actionIDs.length) actionIndicesByAction[game.actionIDs[ike]] = ike;
        this.game = game;
        this.config = config;
        this.id = id;
    }

    public function choose():GameEventType {
        throw "Override this.";
        return null;
    }
}
