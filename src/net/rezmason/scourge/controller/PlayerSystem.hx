package net.rezmason.scourge.controller;

import haxe.Unserializer;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.UnixTime;
import net.rezmason.utils.Zig;

class PlayerSystem {

    private var game:Game;
    private var floats:Array<Float>;
    private var playSignal:Zig<Player->GameEvent->Void>;
    private var onAlert:Void->Void;

    function new():Void {
        game = new Game();
        floats = [];
    }

    private function processGameEventType(type:GameEventType):Void {
        switch (type) {
            case PlayerAction(action, move):
                if (game.hasBegun) updateGame(action, move);
                if (isMyTurn()) play();
            case RefereeAction(action):
                switch (action) {
                    case AllReady: if (isMyTurn()) play();
                    case Connect: connect();
                    case Disconnect: disconnect();
                    case Init(data): init(Unserializer.run(data));
                    case RandomFloats(data): appendFloats(Unserializer.run(data));
                    case Resume(data): resume(Unserializer.run(data));
                    case Save:
                }
            case Ready:
        }
    }

    private function init(config:ScourgeConfig):Void game.begin(config, retrieveRandomFloat, onAlert);
    private function resume(save:SavedGame):Void game.begin(save.config, retrieveRandomFloat, onAlert, save.state);
    private function endGame():Void game.end();

    private function announceReady():Void throw "Override this.";
    private function connect():Void throw "Override this.";
    private function disconnect():Void throw "Override this.";
    private function updateGame(actionIndex:Int, move:Int):Void game.chooseMove(actionIndex, move);
    private function play():Void throw "Override this.";

    private function appendFloats(moreFloats:Array<Float>):Void floats = floats.concat(moreFloats);
    private function retrieveRandomFloat():Float return floats.shift();

    private function volley(player:Player, eventType:GameEventType):Void {
        if (eventType != null) playSignal.dispatch(player, {type:eventType, timeIssued:UnixTime.now()});
    }

    private function isMyTurn():Bool {
        throw "Override this.";
        return false;
    }

    private function currentPlayer():Player {
        throw "Override this.";
        return null;
    }
}
