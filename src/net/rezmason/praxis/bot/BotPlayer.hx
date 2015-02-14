package net.rezmason.praxis.bot;

import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.utils.Zig;

@:allow(net.rezmason.praxis.bot.BotSystem)
class BotPlayer implements IPlayer {

    public var index(default, null):Int;

    private var smarts:Smarts;
    private var period:Int;

    @:allow(net.rezmason.praxis.play.Referee)
    private var playSignal:Zig<GameEvent->Void>;

    private function new(index:Int, smarts:Smarts, period:Int):Void {
        this.index = index;
        this.smarts = smarts;
        this.period = period;

        playSignal = new Zig();
    }
}

