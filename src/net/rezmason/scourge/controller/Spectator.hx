package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types.GameEvent;
import net.rezmason.utils.Zig;

interface Spectator {
    public var updateSignal(default, null):Zig<GameEvent->Void>;
}
