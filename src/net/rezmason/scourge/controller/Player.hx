package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types.GameEvent;
import net.rezmason.utils.Zig;

interface Player {
    public var index(default, null):Int;
    public var ready(default, null):Bool;
    public var synced(default, null):Bool;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var updateSignal:Zig<GameEvent->Void>;
}
