package net.rezmason.praxis.human;

import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.praxis.play.PlayerSystem;

class HumanSystem extends PlayerSystem {

    private var humansByIndex:Map<Int, HumanPlayer>;
    private var numHumans:Int;

    public function new():Void {
        super(true, true);
        humansByIndex = new Map();
        numHumans = 0;
    }

    public function createPlayer(index:Int):HumanPlayer {
        var human:HumanPlayer = new HumanPlayer(index);
        human.playSignal.add(onHumanSignal.bind(index));
        humansByIndex[index] = human;
        numHumans++;
        return human;
    }

    private function onHumanSignal(senderIndex:Int, event:GameEvent):Void processGameEvent(event);

    override private function play():Void currentPlayer().choose();
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && currentPlayer() != null;
    private inline function currentPlayer():HumanPlayer return humansByIndex[game.currentPlayer];
}
