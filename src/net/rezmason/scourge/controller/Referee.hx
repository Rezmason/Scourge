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

typedef RefereeParams = {
    var playerDefs:Array<PlayerDef>;
    var randGen:Void->Float;
    var gameConfig:ScourgeConfig;
    @:optional var spectators:Array<Spectator>;
    @:optional var savedGame:SavedGame;
    @:optional var syncPeriod:Float;
    @:optional var movePeriod:Float;
}

class Referee {

    var game:Game;
    var gameConfig:ScourgeConfig;
    var players:Array<Player>;
    var spectators:Array<Spectator>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var floatsLog:Array<Float>;
    var allReady:Bool;
    var allSynced:Bool;
    var randGen:Void->Float;
    var floats:Array<Float>;
    var busy:Bool;
    var playerFactory:PlayerFactory;
    var playSignal:PlaySignal;
    var syncPeriod:Null<Float>;
    var movePeriod:Null<Float>;

    public var lastGame(default, null):SavedGame;
    public var lastGameConfig(default, null):ScourgeConfig;
    public var gameBegun(get, never):Bool;
    public var numPlayers(get, never):Int;

    public function new():Void {
        game = new Game();
        allReady = false;
        allSynced = true;
        busy = false;
        floats = [];
        playerFactory = new PlayerFactory();
        playSignal = new Zig();
    }

    public function beginGame(params:RefereeParams):Void {

        if (params.playerDefs.length != params.gameConfig.numPlayers) {
            throw 'Player config specifies ${params.playerDefs.length} players: ' +
                'game config specifies ${params.gameConfig.numPlayers}';
        }

        playSignal.add(handlePlaySignal);

        var savedGame:SavedGame = params.savedGame;
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

        gameConfig = params.gameConfig;
        randGen = params.randGen;
        syncPeriod = params.syncPeriod;
        movePeriod = params.movePeriod;
        spectators = params.spectators;
        // Not sure if this belongs here.
        players = playerFactory.makePlayers(params.playerDefs, playSignal, syncPeriod, movePeriod);
        clearFloats();

        game.begin(params.gameConfig, generateRandomFloat, null, savedGameState);
        refereeCall(getFloatsAction());
        refereeCall(Init(SafeSerializer.run(params.gameConfig), serializedSavedGame));
        refereeCall(Connect);
    }

    public function endGame():Void {
        lastGame = saveGame();
        lastGameConfig = gameConfig;
        allReady = false;
        allSynced = true;
        game.end();
        refereeCall(Disconnect);
        playSignal.remove(handlePlaySignal);
        players = null;
    }

    public function saveGame():SavedGame {
        refereeCall(Save);
        var savedLog:Array<GameEvent> = copyLog(log);
        var savedFloats:Array<Float> = floatsLog.copy();
        return {state:game.save(), log:savedLog, floats:savedFloats, timeSaved:UnixTime.now()};
    }

    public function spitBoard():String return game.spitBoard();

    public function spitMoves():String return game.spitMoves();

    public function spitPlan():String {
        return
        'state:\n${spitAspectLookup(game.plan.stateAspectLookup)}' +
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

    private function handlePlaySignal(player:Player, event:GameEvent):Void {

        if (!gameBegun) throw 'Game has not begun!';

        var playerIndex:Int = players.indexOf(player);

        if (playerIndex == -1)
            throw 'Player is not part of this game!';

        event.player = playerIndex;
        event.timeReceived = UnixTime.now();

        switch (event.type) {
            case PlayerAction(actionType):
                switch (actionType) {
                    case SubmitMove(action, move):
                        if (busy) {
                            throw 'Players must not submit moves synchronously!';
                        }

                        if (game.currentPlayer != playerIndex) {
                            throw 'Player $playerIndex cannot act at this time!';
                        }
                        clearFloats();
                        game.chooseMove(action, move);
                        refereeCall(getFloatsAction());
                        allSynced = false;
                        broadcastAndLog(event);
                        if (game.winner >= 0) endGame(); // TEMPORARY
                    case Ready: readyCheck();
                    case Synced: syncCheck();
                }
            case RefereeAction(_): throw 'Players can\'t send referee calls!';
        }
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(event);
        var wasBusy:Bool = busy;
        //trace('BUSY: BROADCAST');
        busy = true;
        for (player in players) player.updateSignal.dispatch(Reflect.copy(event));
        if (spectators != null) {
            for (spectator in spectators) spectator.updateSignal.dispatch(Reflect.copy(event));
        }
        busy = wasBusy;
        //trace(busy ? 'STILL BUSY' : 'FREE');
    }

    private function refereeCall(action:RefereeActionType):Void {
        broadcastAndLog({type:RefereeAction(action), timeIssued:UnixTime.now()});
    }

    private function readyCheck():Void {
        if (allReady) return;
        var wasBusy:Bool = busy;
        busy = true;
        allReady = true;
        for (player in players) {
            if (!player.ready) {
                allReady = false;
                break;
            }
        }

        if (allReady) refereeCall(AllReady);

        busy = wasBusy;
    }

    private function syncCheck():Void {
        if (allSynced) return;
        var wasBusy:Bool = busy;
        busy = true;
        allSynced = true;
        for (player in players) {
            if (!player.synced) {
                allSynced = false;
                break;
            }
        }

        if (allSynced) refereeCall(AllSynced);

        busy = wasBusy;
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

    private function getFloatsAction():RefereeActionType {
        return RandomFloats(SafeSerializer.run(floats));
    }

    private inline function get_gameBegun():Bool return game.hasBegun;

    private inline function get_numPlayers():Int return players == null ? -1 : players.length;
}
