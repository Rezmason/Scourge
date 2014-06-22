package net.rezmason.scourge.controller;

import haxe.Unserializer;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.UnixTime;
import net.rezmason.utils.Zig;

using Lambda;

class PlayerSystem implements IPlayer {

    public var index(default, null):Int;

    private var game:Game;
    private var floats:Array<Float>;
    private var config:ScourgeConfig;
    private var mediator:IPlayerMediator;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var playSignal:Zig<GameEvent->Void>;
    
    function new(cacheMoves:Bool):Void {
        game = new Game(cacheMoves);
        floats = [];
        mediator = null;
    }

    public function setMediator(med:IPlayerMediator):Void {
        if (mediator != med) {
            removeMediator();
            mediator = med;
            mediator.proceedSignal.add(proceed);
            if (game.hasBegun) mediator.connect(game);
        }
    }

    public function removeMediator():Void {
        if (mediator != null) {
            mediator.proceedSignal.remove(proceed);
            mediator.disconnect();
            mediator = null;
        }
    }

    private function processGameEventType(type:GameEventType):Void {
        switch (type) {
            case RefereeAction(action):
                switch (action) {
                    case Init(configData, saveData): 
                        if (!game.hasBegun) {
                            init(configData, saveData);
                            if (mediator != null) mediator.connect(game);
                            else proceed();
                        }
                    case RelayMove(turn, action, move):
                        if (turn == game.revision) {
                            if (mediator != null) mediator.moveStarts(game.currentPlayer, action, move);
                            if (game.hasBegun) updateGame(action, move);
                            if (mediator != null) mediator.moveStops();
                            else proceed();
                        }
                    case RandomFloats(turn, data): 
                        if (turn == game.revision) floats = Unserializer.run(data);
                    case End: 
                        if (game.hasBegun) {
                            if (mediator != null) mediator.disconnect();
                            end();
                        }
                }
            case _:
        }
    }

    private function init(configData:String, saveData:String):Void {
        var savedState:SavedState = saveData != null ? Unserializer.run(saveData).state : null;
        config = Unserializer.run(configData);
        game.begin(config, retrieveRandomFloat, onMoveStep, savedState);
    }

    private inline function onMoveStep(cause:String):Void if (mediator != null) mediator.moveSteps(cause);

    private function proceed():Void if (isMyTurn()) play();
    private function end():Void game.end();
    private function updateGame(actionIndex:Int, move:Int):Void game.chooseMove(actionIndex, move);
    private function play():Void throw "Override this.";
    private function retrieveRandomFloat():Float return floats.shift();
    private function makeGameEvent(type:GameEventType):GameEvent return {type:type, timeIssued:UnixTime.now()};

    private function isMyTurn():Bool {
        throw "Override this.";
        return false;
    }
}
