package net.rezmason.praxis.play;

import net.rezmason.utils.Zig;

interface IPlayer {
    public var index(default, null):Int;

    @:allow(net.rezmason.praxis.play.Referee)
    private var playSignal:Zig<GameEvent->Void>;
}
