package net.rezmason.ropes.play;

import net.rezmason.utils.Zig;

interface IPlayer {
    public var index(default, null):Int;

    @:allow(net.rezmason.ropes.play.Referee)
    private var playSignal:Zig<GameEvent->Void>;
}
