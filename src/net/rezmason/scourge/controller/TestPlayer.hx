package net.rezmason.scourge.controller;

import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.game.ScourgeConfig;
import net.rezmason.utils.Zig;

typedef TestProxy = Game->(Void->Void)->Void;

class TestPlayer extends PlayerSystem {

    private var proxy:TestProxy;
    private var smarts:Smarts;
    private var random:Void->Float;

    public function new(index:Int, proxy:TestProxy, random:Void->Float):Void {
        super(false, false);
        this.index = index;
        this.proxy = proxy;
        this.random = random;
        smarts = new RandomSmarts();
        
        playSignal = new Zig();
        playSignal.add(processGameEvent);
    }

    override private function init(configData:String, saveData:String):Void {
        super.init(configData, saveData);
        smarts.init(game, config, index, random);
    }

    override private function end():Void proxy(game, game.end);
    override private function play():Void proxy(game, choose);
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && game.currentPlayer == index;
    private function choose():Void playSignal.dispatch(smarts.choose());
}
