package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types.GameEvent;
import net.rezmason.scourge.model.Game;
import net.rezmason.utils.Zig;

class SimpleSpectator extends PlayerSystem implements Spectator {

    public var updateSignal(default, null):Zig<GameEvent->Void>;
    public var viewSignal(default, null):Zig<String->Void>;

    public function new():Void {
        super();
        updateSignal = new Zig();
        updateSignal.add(onUpdate);
        viewSignal = new Zig();
        onAlert = viewSignal.dispatch;
    }

    public function getGame():Game return game;

    private function onUpdate(event:GameEvent):Void {
        processGameEventType(event.type);

        switch (event.type) {
            case PlayerAction(SubmitMove(action, move)): viewSignal.dispatch('Player event');
            case _:
        }
    }

    override private function connect():Void {}
    override private function disconnect():Void endGame();
    override private function isMyTurn():Bool return false;
}
