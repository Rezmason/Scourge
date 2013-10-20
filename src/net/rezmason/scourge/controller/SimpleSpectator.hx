package net.rezmason.scourge.controller;

import msignal.Signal;
import net.rezmason.scourge.controller.Types.GameEvent;
import net.rezmason.scourge.model.Game;

class SimpleSpectator extends PlayerSystem implements Spectator {

    public var updateSignal(default, null):Signal1<GameEvent>;
    public var viewSignal(default, null):Signal0;

    public function new():Void {
        super();
        updateSignal = new Signal1();
        updateSignal.add(onUpdate);
        viewSignal = new Signal0();
    }

    public function getGame():Game return game;

    private function onUpdate(event:GameEvent):Void {
        processGameEventType(event.type);
        // trace(event.type);
        viewSignal.dispatch();
    }

    override private function connect():Void {}
    override private function disconnect():Void endGame();
    override private function isMyTurn():Bool return false;
}
