package net.rezmason.scourge.controller;

import haxe.Unserializer;
import net.rezmason.ropes.Types;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.UnixTime;
import net.rezmason.utils.Zig;

class PlayerSystem {

    private var game:Game;
    private var floats:Array<Float>;
    private var playSignal:Zig<Player->GameEvent->Void>;
    private var onAlert:String->Void;

    function new():Void {
        game = new Game();
        floats = [];
    }

    private function processGameEventType(type:GameEventType):Void {
        switch (type) {
            case PlayerAction(action):
                switch (action) {
                    case SubmitMove(action, move):
                        if (game.hasBegun) updateGame(action, move);
                        // if (isMyTurn()) play();
                    case _:
                }
            case RefereeAction(action):
                switch (action) {
                    case AllReady | AllSynced: if (isMyTurn()) play();
                    case Connect: connect();
                    case Disconnect: disconnect();
                    case Init(configData, saveData): init(configData, saveData);
                    case RandomFloats(data): appendFloats(Unserializer.run(data));
                    case Save:
                }
        }
    }

    private function init(configData:String, saveData:String):Void {
        var savedState:SavedState = saveData != null ? Unserializer.run(saveData).state : null;
        game.begin(Unserializer.run(configData), retrieveRandomFloat, onAlert, savedState);
    }

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
