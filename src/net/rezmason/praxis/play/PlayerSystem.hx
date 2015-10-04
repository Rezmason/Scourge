package net.rezmason.praxis.play;

import haxe.Unserializer;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.utils.Zig;

class PlayerSystem {

    public var index(default, null):Int;
    public var gameBegunSignal(default, null):Zig<GameConfig<Dynamic, Dynamic>->Game->Void> = new Zig();
    public var gameEndedSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveStartSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
    public var moveStopSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveStepSignal(default, null):Zig<String->Void> = new Zig();

    private var game:Game;
    private var config:GameConfig<Dynamic, Dynamic>;
    private var isGameUpdating:Bool = false;
    private var isWaitingToProceed:Bool = false;
    private var usesSignals:Bool;
    
    function new(usesSignals:Bool, cacheMoves:Bool):Void {
        this.usesSignals = usesSignals;
        game = new Game(cacheMoves);
    }

    public function proceed():Void {
        if (!isWaitingToProceed) throw 'Called PlayerSystem::proceed() out of sequence.';
        isWaitingToProceed = false;
        if (isMyTurn()) play();
    }

    private function processGameEvent(type:GameEvent):Void {
        switch (type) {
            case Init(configData, saveData): 
                if (!game.hasBegun) {
                    init(configData, saveData);
                    if (usesSignals) {
                        isWaitingToProceed = true;
                        gameBegunSignal.dispatch(config, game);
                    } else if (isMyTurn()) {
                        play();
                    }
                }
            case RelayMove(turn, action, move):
                if (turn == game.revision) {
                    if (usesSignals) moveStartSignal.dispatch(game.currentPlayer, action, move);
                    isGameUpdating = true;
                    if (game.hasBegun) updateGame(action, move);
                    isGameUpdating = false;
                    if (usesSignals) {
                        isWaitingToProceed = true;
                        moveStopSignal.dispatch();
                    } else if (isMyTurn()) {
                        play();
                    }
                }
            case End: 
                if (game.hasBegun) {
                    if (usesSignals) gameEndedSignal.dispatch();
                    game.end();
                }
            case SubmitMove(_, _, _):
            case Time(_):
        }
    }

    private function init(configData:String, saveData:String):Void {
        var savedState:SavedState = saveData != null ? Unserializer.run(saveData).state : null;
        config = Unserializer.run(configData);
        game.begin(config, onMoveStep, savedState);
    }

    private inline function onMoveStep(cause:String):Void {
        if (isGameUpdating && usesSignals) moveStepSignal.dispatch(cause);
    }

    private function updateGame(actionID:String, move:Int):Void game.chooseMove(actionID, move);
    private function play():Void throw "Override this.";

    private function isMyTurn():Bool {
        throw "Override this.";
        return false;
    }
}
