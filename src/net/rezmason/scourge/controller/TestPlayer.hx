package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.Zig;

typedef TestProxy = Game->(Void->Void)->Void;

class TestPlayer extends PlayerSystem implements Player {

    public var index(default, null):Int;
    public var ready(default, null):Bool;
    public var synced(default, null):Bool;

    private var proxy:TestProxy;
    private var smarts:Smarts;
    private var random:Void->Float;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var updateSignal:Zig<GameEvent->Void>;

    public function new(index:Int, playSignal:PlaySignal, proxy:TestProxy, random:Void->Float):Void {
        super(false);
        this.index = index;
        this.playSignal = playSignal;
        this.proxy = proxy;
        this.random = random;
        smarts = new RandomSmarts();
        synced = true; // TestPlayer is always synced

        updateSignal = new Zig();
        updateSignal.add(function(event:GameEvent):Void processGameEventType(event.type));
    }

    override private function announceReady():Void {
        ready = true;
        volley(this, PlayerAction(Ready));
    }

    override private function updateGame(actionIndex:Int, move:Int):Void {
        super.updateGame(actionIndex, move);
        volley(this, PlayerAction(Synced));
    }

    override private function init(configData:String, saveData:String):Void {
        super.init(configData, saveData);
        smarts.init(game, config, index, random);
    }

    override private function connect():Void proxy(game, announceReady);
    override private function disconnect():Void proxy(game, endGame);
    override private function play():Void proxy(game, choose);
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && game.currentPlayer == index;
    override private function currentPlayer():Player return this;
    private function choose():Void volley(currentPlayer(), smarts.choose());
}
