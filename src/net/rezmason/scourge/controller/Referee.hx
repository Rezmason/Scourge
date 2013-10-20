package net.rezmason.scourge.controller;

import haxe.Timer;

import msignal.Signal;

import net.rezmason.ropes.Types;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.UnixTime;

using Lambda;

typedef RandGen = Void->Float;

class Referee {

    var game:Game;
    var gameConfig:ScourgeConfig;
    var players:Array<Player>;
    var spectators:Array<Spectator>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var allReady:Bool;
    var randGen:RandGen;
    var floats:Array<Float>;
    var busy:Bool;
    var playerFactory:PlayerFactory;
    var playSignal:Signal2<Player, GameEvent>;

    public var gameBegun(get, never):Bool;
    public var numPlayers(get, never):Int;

    public function new():Void {
        game = new Game();
        allReady = false;
        busy = false;
        floats = [];
        playerFactory = new PlayerFactory();
        playSignal = new Signal2();
    }

    public function beginGame(playerDefs:Array<PlayerDef>, spectators:Array<Spectator>, randGen:RandGen, gameConfig:ScourgeConfig):Void {
        if (playerDefs.length != gameConfig.numPlayers)
            throw 'Player config specifies ${playerDefs.length} players: game config specifies ${gameConfig.numPlayers}';

        playSignal.add(handlePlaySignal);

        log = [];
        this.gameConfig = gameConfig;
        this.randGen = randGen;
        players = playerFactory.makePlayers(playerDefs, playSignal);
        if (spectators == null) spectators = [];
        this.spectators = spectators;
        clearFloats();
        game.begin(gameConfig, generateRandomFloat);
        refereeCall(getFloatsAction());
        refereeCall(Init(SafeSerializer.run(gameConfig)));
        refereeCall(Connect);
    }

    public function resumeGame(playerDefs:Array<PlayerDef>, spectators:Array<Spectator>, randGen:RandGen, savedGame:SavedGame):Void {
        if (playerDefs.length != savedGame.config.numPlayers)
            throw 'Player config specifies ${playerDefs.length} players: saved game specifies ${savedGame.config.numPlayers}';

        log = copyLog(savedGame.log);
        this.gameConfig = savedGame.config;
        players = playerFactory.makePlayers(playerDefs, playSignal);
        if (spectators == null) spectators = [];
        this.spectators = spectators;
        game.begin(gameConfig, generateRandomFloat, savedGame.state);

        refereeCall(Resume(SafeSerializer.run(savedGame)));
        refereeCall(Connect);
    }

    public function endGame():Void {
        allReady = false;
        game.end();
        refereeCall(Disconnect);
        playSignal.remove(handlePlaySignal);
        players = null;
    }

    public function saveGame():SavedGame {
        refereeCall(Save);
        var savedLog:Array<GameEvent> = copyLog(log);
        return {state:game.save(), log:savedLog, config:gameConfig, timeSaved:UnixTime.now()};
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

        if (busy)
            throw 'Players must not dispatch events synchronously!';

        if (!gameBegun)
            throw 'Game has not begun!';

        var playerIndex:Int = players.indexOf(player);

        if (playerIndex == -1)
            throw 'Player is not part of this game!';

        event.player = playerIndex;
        event.timeReceived = UnixTime.now();

        switch (event.type) {
            case PlayerAction(action, move):
                if (game.currentPlayer != playerIndex)
                    throw 'Player $playerIndex cannot act at this time!';
                clearFloats();
                game.chooseMove(action, move);
                refereeCall(getFloatsAction());
                broadcastAndLog(event);
                if (game.winner >= 0) endGame(); // TEMPORARY
            case RefereeAction(_):
                throw 'Players can\'t send referee calls!';
            case Ready:
                readyCheck();
        }
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(event);
        var wasBusy:Bool = busy;
        //trace('BUSY: BROADCAST');
        busy = true;
        for (player in players) player.updateSignal.dispatch(Reflect.copy(event));
        for (spectator in spectators) spectator.updateSignal.dispatch(Reflect.copy(event));
        busy = wasBusy;
        //trace(busy ? 'STILL BUSY' : 'FREE');
    }

    private function refereeCall(action:RefereeActionType):Void {
        broadcastAndLog({type:RefereeAction(action), timeIssued:UnixTime.now()});
    }

    private function readyCheck():Void {
        if (allReady) return;
        var wasBusy:Bool = busy;
        //trace('BUSY: READY CHECK');
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
        //trace(busy ? 'STILL BUSY' : 'FREE');
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
        return float;
    }

    private function getFloatsAction():RefereeActionType {
        return RandomFloats(SafeSerializer.run(floats));
    }

    private inline function get_gameBegun():Bool return game.hasBegun;

    private inline function get_numPlayers():Int return players == null ? -1 : players.length;
}
