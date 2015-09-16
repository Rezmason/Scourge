package net.rezmason.praxis.play;

import haxe.Timer;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.UnixTime;

class Referee {

    var game:Game;
    var gameConfig:GameConfig<Dynamic, Dynamic>;
    var players:Array<IPlayer>;
    var playerListeners:Array<GameEvent->Void>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var floatsLog:Array<Float>;
    var randGen:Void->Float;
    var busy:Bool;

    public var lastGame(default, null):SavedGame;
    public var lastGameConfig(default, null):GameConfig<Dynamic, Dynamic>;
    public var gameBegun(get, never):Bool;
    public var numPlayers(get, never):Int;

    public function new():Void {
        game = new Game(false);
        busy = false;
    }

    public function beginGame(players:Array<IPlayer>, randGen:Void->Float, gameConfig:GameConfig<Dynamic, Dynamic>, savedGame:SavedGame = null):Void {

        if (players.length != gameConfig.params['build'].numPlayers) {
            throw 'Player config has ${players.length} players: ' +
                'game config requires ${gameConfig.params['build'].numPlayers}';
        }

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
        this.players = players;
        playerListeners = [];
        for (ike in 0...numPlayers) {
            playerListeners[ike] = handlePlaySignal.bind(ike);
            players[ike].playSignal.add(playerListeners[ike]);
        }
        
        game.begin(gameConfig, null, savedGameState);
        broadcastAndLog(Init(SafeSerializer.run(gameConfig), serializedSavedGame));
    }

    public function endGame():Void {
        lastGame = saveGame();
        lastGameConfig = gameConfig;
        game.end();
        broadcastAndLog(End);
        for (ike in 0...numPlayers) players[ike].playSignal.remove(playerListeners[ike]);
        playerListeners = null;
        players = null;
    }

    public function saveGame():SavedGame {
        var savedLog:Array<GameEvent> = log.copy();
        var savedFloats:Array<Float> = floatsLog.copy();
        return {state:game.save(), log:savedLog, floatsLog:savedFloats, timeSaved:UnixTime.now()};
    }

    private function handlePlaySignal(playerIndex:Int, event:GameEvent):Void {
        switch (event) {
            case SubmitMove(turn, action, move):
                if (!gameBegun) throw 'Game has not begun!';
                if (playerIndex == game.currentPlayer && turn == game.revision) {
                    if (busy) throw 'Players must not submit moves synchronously!';
                    if (game.isRuleRandom(action)) {
                        move = Std.int(generateRandomFloat() * game.getMovesForAction(action).length);
                    }
                    game.chooseMove(action, move);
                    broadcastAndLog(RelayMove(turn, action, move));
                    if (game.winner >= 0) endGame(); // TEMPORARY
                }
            case _:
        }
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(Time(UnixTime.now()));
        log.push(event);
        var wasBusy:Bool = busy;
        busy = true;
        for (player in players) player.playSignal.dispatch(event);
        busy = wasBusy;
    }

    private function generateRandomFloat():Float {
        var float:Float = randGen();
        floatsLog.push(float);
        return float;
    }

    private inline function get_gameBegun():Bool return game.hasBegun;

    private inline function get_numPlayers():Int return players == null ? -1 : players.length;
}
