package net.rezmason.praxis.play;

import haxe.Timer;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.UnixTime;
import net.rezmason.utils.Zig;

class Referee {

    var game:Game;
    var gameConfig:GameConfig<Dynamic, Dynamic>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var floatsLog:Array<Float>;
    var randGen:Void->Float;
    var waitingToProceed:Bool;
    public var gameEventSignal(default, null):Zig<GameEvent->Void> = new Zig();

    public var lastGame(default, null):SavedGame;
    public var lastGameConfig(default, null):GameConfig<Dynamic, Dynamic>;
    public var gameBegun(get, never):Bool;

    public function new():Void {
        game = new Game(false);
        waitingToProceed = false;
    }

    public function beginGame(randGen:Void->Float, gameConfig:GameConfig<Dynamic, Dynamic>, savedGame:SavedGame = null):Void {

        var serializedSavedGame:String = null;
        var savedGameState:SavedState = null;

        log = [];
        floatsLog = [];

        if (savedGame != null) {
            log = savedGame.log.copy();
            floatsLog = savedGame.floatsLog.copy();
            serializedSavedGame = SafeSerializer.run(savedGame);
            savedGameState = savedGame.state;
        }

        this.gameConfig = gameConfig;
        this.randGen = randGen;
        
        game.begin(gameConfig, null, savedGameState);
        waitingToProceed = true;
        broadcastAndLog(Init(SafeSerializer.run(gameConfig), serializedSavedGame));
    }

    public function endGame():Void {
        lastGame = saveGame();
        lastGameConfig = gameConfig;
        game.end();
        broadcastAndLog(End);
        gameEventSignal.removeAll();
    }

    public function saveGame():SavedGame {
        var savedLog:Array<GameEvent> = log.copy();
        var savedFloats:Array<Float> = floatsLog.copy();
        return {state:game.save(), log:savedLog, floatsLog:savedFloats, timeSaved:UnixTime.now()};
    }

    public function submitMove(event:GameEvent):Void {
        switch (event) {
            case SubmitMove(turn, actionID, move):
                if (!gameBegun) throw 'Game has not begun!';
                if (turn != game.revision) throw 'Move submitted out of turn.';
                if (waitingToProceed) throw 'Players must wait until the game proceeds!';
                if (game.isRuleRandom(actionID)) {
                    move = Std.int(generateRandomFloat() * game.getMovesForAction(actionID).length);
                }
                game.chooseMove(actionID, move);
                waitingToProceed = true;
                broadcastAndLog(SubmitMove(turn, actionID, move));
                if (game.winner >= 0) endGame(); // TEMPORARY
            case _:
                throw 'Game event is not a SubmitMove.';
        }
    }

    public function proceed():Void {
        waitingToProceed = false;
        broadcastAndLog(Proceed(game.revision));
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(Time(UnixTime.now()));
        log.push(event);
        gameEventSignal.dispatch(event);
    }

    private function generateRandomFloat():Float {
        var float:Float = randGen();
        floatsLog.push(float);
        return float;
    }

    private inline function get_gameBegun():Bool return game.hasBegun;
}
