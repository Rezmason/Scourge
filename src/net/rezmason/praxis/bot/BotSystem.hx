package net.rezmason.praxis.bot;

import haxe.Timer;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.PlayerSystem;

typedef Bot = {smarts:Smarts, period:Int};

class BotSystem extends PlayerSystem {

    var botsByIndex:Map<Int, Bot>;
    var random:Void->Float;
    var beatTimer:Timer;

    public function new() super(true);

    public function reset(random:Void->Float):Void {
        if (beatTimer != null) beatTimer.stop();
        beatTimer = null;
        botsByIndex = new Map();
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
        if (beatTimer != null) beatTimer.stop();
        beatTimer = new Timer(period);
        beatTimer.run = onBeat.bind(cbk);
    }

    function onBeat(cbk:Void->Void):Void {
        beatTimer.stop();
        if (game.hasBegun) cbk();
    }

    inline function currentPlayer():Bot return botsByIndex[game.currentPlayer];
}
