package net.rezmason.scourge.controller;

import msignal.Signal;
import net.rezmason.scourge.controller.Types.GameEvent;

interface Player {
    public var index(default, null):Int;
    public var ready(default, null):Bool;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var updateSignal:Signal1<GameEvent>;
}
