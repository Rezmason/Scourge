package net.rezmason.praxis.bot;

import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.utils.Zig;

class BotPlayer implements IPlayer {

    public var index(default, null):Int;
    public var period(default, null):Int;
    public var playSignal(default, null):Zig<GameEvent->Void> = new Zig();
    
    @:allow(net.rezmason.praxis.bot.BotSystem) var smarts:Smarts;

    @:allow(net.rezmason.praxis.bot.BotSystem)
    private function new(index:Int, smarts:Smarts, period:Int):Void {
        this.index = index;
        this.smarts = smarts;
        this.period = period;
    }

    public function choose():Void playSignal.dispatch(smarts.choose());
}

