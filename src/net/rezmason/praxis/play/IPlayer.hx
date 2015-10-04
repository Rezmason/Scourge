package net.rezmason.praxis.play;

import net.rezmason.utils.Zig;

interface IPlayer {
    public var index(default, null):Int;
    public var playSignal(default, null):Zig<GameEvent->Void>;
}
