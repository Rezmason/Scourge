package net.rezmason.praxis.human;

import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.utils.Zig;

@:allow(net.rezmason.praxis.human.HumanSystem)
class HumanPlayer implements IPlayer {

    public var index(default, null):Int;

    @:allow(net.rezmason.praxis.play.Referee)
    private var playSignal:Zig<GameEvent->Void>;

    private function new(index:Int):Void {
        this.index = index;
        playSignal = new Zig();
    }

    public function choose():Void {
        // TODO: dispatch signal to enable UI
    }
}

