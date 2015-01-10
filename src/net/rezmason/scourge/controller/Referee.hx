package net.rezmason.scourge.controller;

import haxe.Timer;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.UnixTime;
import net.rezmason.utils.Zig;

using Lambda;

class Referee {

    var game:Game;
    var gameConfig:ScourgeConfig;
    var players:Array<IPlayer>;
    var playerListeners:Array<GameEvent->Void>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var floatsLog:Array<Float>;
    var randGen:Void->Float;
    var floats:Array<Float>;
    var busy:Bool;

    public var lastGame(default, null):SavedGame;
    public var lastGameConfig(default, null):ScourgeConfig;
    public var gameBegun(get, never):Bool;
    public var numPlayers(get, never):Int;

    public function new():Void {
        game = new Game(false);
        busy = false;
        floats = [];
    }

    public function beginGame(players:Array<IPlayer>, randGen:Void->Float, gameConfig:ScourgeConfig, savedGame:SavedGame = null):Void {

        if (players.length != gameConfig.numPlayers) {
            throw 'Player config has ${players.length} players: ' +
                'game config requires ${gameConfig.numPlayers}';
        }

        var serializedSavedGame:String = null;
        var savedGameState:SavedState = null;

        log = [];
        floatsLog = [];

        if (savedGame != null) {
            log = copyLog(savedGame.log);
            floatsLog = savedGame.floats.copy();
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
        clearFloats();

        game.begin(gameConfig, generateRandomFloat, null, savedGameState);
        refereeCall(getFloatsAction(0));
        refereeCall(Init(SafeSerializer.run(gameConfig), serializedSavedGame));
    }

    public function endGame():Void {
        lastGame = saveGame();
        lastGameConfig = gameConfig;
        game.end();
        refereeCall(End);
        for (ike in 0...numPlayers) players[ike].playSignal.remove(playerListeners[ike]);
        playerListeners = null;
        players = null;
    }

    public function saveGame():SavedGame {
        var savedLog:Array<GameEvent> = copyLog(log);
        var savedFloats:Array<Float> = floatsLog.copy();
        return {state:game.save(), log:savedLog, floats:savedFloats, timeSaved:UnixTime.now()};
    }

    public function spitBoard():String return game.spitBoard();

    public function spitMoves():String return game.spitMoves();

    public function spitPlan():String {
        return
        'global:\n${spitAspectLookup(game.plan.globalAspectLookup)}' +
        'player:\n${spitAspectLookup(game.plan.playerAspectLookup)}' +
        'node:\n${spitAspectLookup(game.plan.nodeAspectLookup)}';
    }

    function spitAspectLookup(lkp:AspectLookup):String {
        var str:String = '';
        var arr:Array<String> = [];
        for (key in lkp.keys()) {
            var ptr = lkp[key];
            arr[ptr.toInt()] = '\t$key: ${ptr.toInt()}, ';
        }
        return str + arr.join('\n') + '\n';
    }

    private function handlePlaySignal(playerIndex:Int, event:GameEvent):Void {

        event.timeReceived = UnixTime.now();

        switch (event.type) {
            case SubmitMove(turn, action, move):
                if (!gameBegun) throw 'Game has not begun!';
                if (playerIndex == game.currentPlayer && turn == game.revision) {
                    if (busy) throw 'Players must not submit moves synchronously!';
                    clearFloats();
                    game.chooseMove(action, move);
                    // trace(game.spitBoard());
                    refereeCall(getFloatsAction(game.revision - 1));
                    refereeCall(RelayMove(turn, action, move));
                    if (game.winner >= 0) endGame(); // TEMPORARY
                }
            case _:
        }
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(event);
        var wasBusy:Bool = busy;
        //trace('BUSY: BROADCAST');
        busy = true;
        for (player in players) player.playSignal.dispatch(Reflect.copy(event));
        busy = wasBusy;
        //trace(busy ? 'STILL BUSY' : 'FREE');
    }

    private function refereeCall(action:GameEventType):Void {
        broadcastAndLog({type:action, timeIssued:UnixTime.now()});
    }

    private inline static function copyLog(source:Array<GameEvent>):Array<GameEvent> {
        return source.map(Reflect.copy).array();
    }

    private function clearFloats():Void {
        floats.splice(0, floats.length);
    }

    private function generateRandomFloat():Float {
        var float:Float = randGen();
        floats.push(float);
        floatsLog.push(float);
        return float;
    }

    private function getFloatsAction(rev:Int):GameEventType {
        return RandomFloats(rev, SafeSerializer.run(floats));
    }

    private inline function get_gameBegun():Bool return game.hasBegun;

    private inline function get_numPlayers():Int return players == null ? -1 : players.length;
}
