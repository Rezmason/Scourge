package net.rezmason.scourge.controller;

import msignal.Signal;
import net.rezmason.scourge.controller.Types.GameEvent;

interface Spectator {
    public var updateSignal(default, null):Signal1<GameEvent>;
}
