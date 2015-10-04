package net.rezmason.scourge.game.test;

import net.rezmason.praxis.bot.Smarts;
import net.rezmason.praxis.bot.RandomSmarts;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.utils.Zig;

typedef TestProxy = Game->(Void->Void)->Void;

class TestPlayer extends PlayerSystem {

    private var index:Int;
    private var proxy:TestProxy;
    private var smarts:Smarts;
    private var random:Void->Float;

    public function new(index:Int, proxy:TestProxy, random:Void->Float):Void {
        super(false);
        this.index = index;
        this.proxy = proxy;
        this.random = random;
        smarts = new RandomSmarts();
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
