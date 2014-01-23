package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.utils.Zig;

@:allow(net.rezmason.scourge.controller.BotSystem)
class BotPlayer implements Player {

    public var index(default, null):Int;
    public var ready(default, null):Bool;
    public var synced(default, null):Bool;

    private var smarts:Smarts;
    private var period:Int;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var updateSignal:Zig<GameEvent->Void>;

    private function new(signal:Zig<Int->GameEvent->Void>, index:Int, smarts:Smarts, period:Int):Void {
        this.index = index;
        this.smarts = smarts;
        this.period = period;

        synced = true; // BotPlayer is always synced

        updateSignal = new Zig();
        updateSignal.add(signal.dispatch.bind(index));
    }

}
