package net.rezmason.scourge.controller;

import haxe.Timer;

import net.rezmason.ropes.Types;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.UnixTime;

using Lambda;
using Reflect;

typedef RandGen = Void->Float;

class Referee {

    var game:Game;
    var gameConfig:ScourgeConfig;
    var players:Array<Player>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var allReady:Bool;
    var randGen:RandGen;
    var floats:Array<Float>;
    var busy:Bool;

    public var gameBegun(getHasBegun, null):Bool;

    public function new():Void {
        game = new Game();
        allReady = false;
        busy = false;
        floats = [];
    }

    public function beginGame(playerConfigs:Array<PlayerConfig>, randGen:RandGen, gameConfig:ScourgeConfig):Void {
        if (playerConfigs.length != gameConfig.numPlayers)
            throw "Player config specifies " + playerConfigs.length + " players: game config specifies " + gameConfig.numPlayers;

        log = [];
        this.gameConfig = gameConfig;
        this.randGen = randGen;
        players = PlayerFactory.makePlayers(playerConfigs, handlePlayerEvent);
        clearFloats();
        game.begin(gameConfig, generateRandomFloat);
        refereeCall(getFloatsAction());
        refereeCall(Init(SafeSerializer.run(gameConfig)));
        refereeCall(Connect);
    }

    public function resumeGame(playerConfigs:Array<PlayerConfig>, randGen:RandGen, savedGame:SavedGame):Void {
        if (playerConfigs.length != savedGame.config.numPlayers)
            throw "Player config specifies " + playerConfigs.length + " players: saved game specifies " + savedGame.config.numPlayers;

        log = copyLog(savedGame.log);
        this.gameConfig = savedGame.config;
        players = PlayerFactory.makePlayers(playerConfigs, handlePlayerEvent);
        game.begin(gameConfig, generateRandomFloat, savedGame.state);

        refereeCall(Resume(SafeSerializer.run(savedGame)));
        refereeCall(Connect);
    }

    public function endGame():Void {
        allReady = false;
        game.end();
        refereeCall(Disconnect);
        players = null;
    }

    public function saveGame():SavedGame {
        refereeCall(Save);
        var savedLog:Array<GameEvent> = copyLog(log);
        return {state:game.save(), log:savedLog, config:gameConfig, timeSaved:UnixTime.now()};
    }

    public function spitBoard():String {
        return game.spitBoard();
    }

    private function handlePlayerEvent(player:Player, event:GameEvent):Void {

        if (busy)
            throw "Players must not dispatch events synchronously!";

        if (!gameBegun)
            throw "Game has not begun!";

        var playerIndex:Int = players.indexOf(player);

        if (playerIndex == -1)
            throw "Player is not part of this game!";

        event.player = playerIndex;
        event.timeReceived = UnixTime.now();

        switch (event.type) {
            case PlayerAction(action, option):
                if (game.currentPlayer != playerIndex)
                    throw "Player " + playerIndex + " cannot act at this time!";
                clearFloats();
                game.chooseOption(action, option);
                if (game.winner >= 0) game.end(); // TEMPORARY
                refereeCall(getFloatsAction());
                broadcastAndLog(event);
            case RefereeAction(action):
                throw "Player's can't send referee calls!";
            case Ready:
                readyCheck();
        }
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(event);
        var wasBusy:Bool = busy;
        //trace("BUSY: BROADCAST");
        busy = true;
        for (player in players) player.send(event.copy());
        busy = wasBusy;
        //trace(busy ? "STILL BUSY" : "FREE");
    }

    private function refereeCall(action:RefereeActionType):Void {
        broadcastAndLog({type:RefereeAction(action), timeIssued:UnixTime.now()});
    }

    private function readyCheck():Void {
        if (allReady) return;
        var wasBusy:Bool = busy;
        //trace("BUSY: READY CHECK");
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
        //trace(busy ? "STILL BUSY" : "FREE");
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

    private inline function getHasBegun():Bool { return game.hasBegun; }
}
