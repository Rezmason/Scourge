package net.rezmason.praxis.human;

import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.utils.Zig;

class HumanPlayer implements IPlayer {

    public var index(default, null):Int;
    public var playSignal(default, null):Zig<GameEvent->Void> = new Zig();
    public var chooseSignal(default, null):Zig<Void->Void> = new Zig();

    @:allow(net.rezmason.praxis.human.HumanSystem) private function new(index:Int):Void this.index = index;
    public function choose():Void chooseSignal.dispatch();
    public function submitMove(turn, action, move) playSignal.dispatch(SubmitMove(turn, action, move));
}
