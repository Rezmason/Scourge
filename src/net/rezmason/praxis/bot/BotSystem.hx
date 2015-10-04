package net.rezmason.praxis.bot;

import haxe.Timer;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.PlayerSystem;

typedef Bot = {smarts:Smarts, period:Int};

class BotSystem extends PlayerSystem {

    var botsByIndex:Map<Int, Bot> = new Map();
    var random:Void->Float;

    public function new(random:Void->Float):Void {
        super(true);
        this.random = random;
    }

    public function createPlayer(index:Int, smarts:Smarts, period:Int) {
        botsByIndex[index] = {smarts:smarts, period:period};
    }

    override function init(configData:String, saveData:String):Void {
        super.init(configData, saveData);
        for (index in botsByIndex.keys()) botsByIndex[index].smarts.init(game, config, index, random);
    }

    override function play():Void beat(choose);
    
    override function isMyTurn():Bool return game.hasBegun && game.winner < 0 && currentPlayer() != null;

    function choose() playSignal.dispatch(currentPlayer().smarts.choose());

    function beat(cbk:Void->Void):Void {
        var period:Int = 10;
        if (game.hasBegun) period = currentPlayer().period;
        var timer:Timer = new Timer(period);
        timer.run = onBeat.bind(timer, cbk);
    }

    function onBeat(timer:Timer, cbk:Void->Void):Void {
        timer.stop();
        if (game.hasBegun) cbk();
    }

    inline function currentPlayer():Bot return botsByIndex[game.currentPlayer];
}
