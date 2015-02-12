package net.rezmason.ropes;

import net.rezmason.utils.Zig;

interface IPlayer {
    public var index(default, null):Int;

    @:allow(net.rezmason.ropes.Referee)
    private var playSignal:Zig<GameEvent->Void>;
}
