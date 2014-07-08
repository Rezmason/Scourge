package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.utils.Zig;

@:allow(net.rezmason.scourge.controller.BotSystem)
class BotPlayer implements IPlayer {

    public var index(default, null):Int;

    private var smarts:Smarts;
    private var period:Int;

    @:allow(net.rezmason.scourge.controller.Referee)
    @:allow(net.rezmason.scourge.controller.BotSystem)
    private var playSignal:Zig<GameEvent->Void>;

    private function new(index:Int, smarts:Smarts, period:Int):Void {
        this.index = index;
        this.smarts = smarts;
        this.period = period;

        playSignal = new Zig();
    }
}
