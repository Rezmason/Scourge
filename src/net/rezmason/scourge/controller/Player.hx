package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.UnixTime;

class Player {

    private var handler:Player->GameEvent->Void;
    private var game:Game;
    private var config:PlayerConfig;
    private var gameConfig:ScourgeConfig;
    private var index:Int;

    public var ready(default, null):Bool;

    function new(index:Int, config:PlayerConfig, handler:Player->GameEvent->Void):Void {
        this.index = index;
        this.handler = handler;
        this.config = config;
        game = new Game();
        prime();
    }

    @:allow(net.rezmason.scourge.controller.Referee)
    private function send(event:GameEvent):Void {
        if (!ready && Type.enumConstructor(event.type) == 'PlayerAction')
            throw 'This player is not yet ready!';
        processEvent(event);
    }

    private function prime():Void {}

    private function processEvent(event:GameEvent):Void {}

    private function now():Int { return UnixTime.now(); }
}
