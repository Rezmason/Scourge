package net.rezmason.scourge.controller;

import haxe.Unserializer;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.Zig;

using Lambda;

class PlayerSystem implements IPlayer {

    public var index(default, null):Int;
    public var gameBegunSignal(default, null):Zig<Game->Void> = new Zig();
    public var gameEndedSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveStartSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
    public var moveStopSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveStepSignal(default, null):Zig<String->Void> = new Zig();

    private var game:Game;
    private var floats:Array<Float> = [];
    private var config:ScourgeConfig;
    private var isGameUpdating:Bool = false;
    private var isWaitingToProceed:Bool = false;
    private var usesSignals:Bool;

    @:allow(net.rezmason.scourge.controller.Referee)
    private var playSignal:Zig<GameEvent->Void>;
    
    function new(usesSignals:Bool, cacheMoves:Bool):Void {
        this.usesSignals = usesSignals;
        game = new Game(cacheMoves);
    }

    public function proceed():Void {
        if (!isWaitingToProceed) throw 'Called PlayerSystem::proceed() out of sequence.';
        isWaitingToProceed = false;
        takeTurn();
    }

    private function processGameEvent(type:GameEvent):Void {
        switch (type) {
            case Init(configData, saveData): 
                if (!game.hasBegun) {
                    init(configData, saveData);
                    if (usesSignals) {
                        isWaitingToProceed = true;
                        gameBegunSignal.dispatch(game);
                    } else {
                        takeTurn();
                    }
                }
            case RelayMove(turn, action, move):
                if (turn == game.revision) {
                    if (usesSignals) moveStartSignal.dispatch(game.currentPlayer, game.actionIDs[action], move);
                    isGameUpdating = true;
                    if (game.hasBegun) updateGame(action, move);
                    isGameUpdating = false;
                    if (usesSignals) {
                        isWaitingToProceed = true;
                        moveStopSignal.dispatch();
                    } else {
                        takeTurn();
                    }
                }
            case RandomFloats(turn, data): 
                if (turn == game.revision) floats = Unserializer.run(data);
            case End: 
                if (game.hasBegun) {
                    if (usesSignals) gameEndedSignal.dispatch();
                    end();
                }
            case _:
        }
    }

    private function init(configData:String, saveData:String):Void {
        var savedState:SavedState = saveData != null ? Unserializer.run(saveData).state : null;
        config = Unserializer.run(configData);
        game.begin(config, retrieveRandomFloat, onMoveStep, savedState);
    }

    private inline function onMoveStep(cause:String):Void {
        if (isGameUpdating && usesSignals) moveStepSignal.dispatch(cause);
    }

    private function takeTurn():Void if (isMyTurn()) play();
    private function end():Void game.end();
    private function updateGame(actionIndex:Int, move:Int):Void game.chooseMove(actionIndex, move);
    private function play():Void throw "Override this.";
    private function retrieveRandomFloat():Float return floats.shift();

    private function isMyTurn():Bool {
        throw "Override this.";
        return false;
    }
}
