package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes.GameEvent;
import net.rezmason.utils.Zig;

interface IPlayer {
    public var index(default, null):Int;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var playSignal:Zig<GameEvent->Void>;
}
