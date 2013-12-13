package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.Zig;

typedef TestProxy = Game->(Void->Void)->Void;

class TestPlayer extends PlayerSystem implements Player {

    public var index(default, null):Int;
    public var ready(default, null):Bool;

    private var proxy:TestProxy;
    private var smarts:Smarts;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var updateSignal:Zig<GameEvent->Void>;

    public function new(index:Int, playSignal:Zig<Player->GameEvent->Void>, proxy:TestProxy):Void {
        super();
        this.index = index;
        this.playSignal = playSignal;
        this.proxy = proxy;
        smarts = new RandomSmarts();

        updateSignal = new Zig();
        updateSignal.add(function(event:GameEvent):Void processGameEventType(event.type));
    }

    override private function announceReady():Void {
        ready = true;
        volley(this, Ready);
    }

    override private function init(config:ScourgeConfig):Void {
        super.init(config);
        smarts.init(game);
    }

    override private function resume(save:SavedGame):Void {
        super.resume(save);
        smarts.init(game);
    }

    override private function connect():Void proxy(game, announceReady);
    override private function disconnect():Void proxy(game, endGame);
    override private function play():Void proxy(game, choose);
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && game.currentPlayer == index;
    override private function currentPlayer():Player return this;
    private function choose():Void volley(currentPlayer(), smarts.choose(game));
}
