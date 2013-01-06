package net.rezmason.scourge.controller;

import haxe.Timer;

import net.rezmason.utils.SafeSerializer;
import net.rezmason.ropes.Types;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;

using Lambda;
using Reflect;

class Referee {

    var game:Game;
    var gameConfig:ScourgeConfig;
    var players:Array<Player>;
    var gameTimer:Timer;
    var log:Array<GameEvent>;
    var allReady:Bool;

    public var gameBegun(getHasBegun, null):Bool;

    public function new():Void {
        game = new Game();
        allReady = false;
    }

    public function beginGame(playerConfigs:Array<PlayerConfig>, randomFunction:Void->Float, gameConfig:ScourgeConfig):Void {
        if (playerConfigs.length != gameConfig.numPlayers)
            throw "Player config specifies " + playerConfigs.length + " players: game config specifies " + gameConfig.numPlayers;

        log = [];
        this.gameConfig = gameConfig;
        players = PlayerFactory.makePlayers(playerConfigs);
        game.begin(gameConfig, randomFunction);

        refereeCall(Init(SafeSerializer.run(gameConfig)));
        refereeCall(Connect(handlePlayerEvent));
    }

    public function resumeGame(playerConfigs:Array<PlayerConfig>, randomFunction:Void->Float, savedGame:SavedGame):Void {
        if (playerConfigs.length != savedGame.config.numPlayers)
            throw "Player config specifies " + playerConfigs.length + " players: saved game specifies " + savedGame.config.numPlayers;

        log = copyLog(savedGame.log);
        this.gameConfig = savedGame.config;
        players = PlayerFactory.makePlayers(playerConfigs);
        game.begin(gameConfig, randomFunction, savedGame.state);

        refereeCall(Resume(SafeSerializer.run(savedGame)));
        refereeCall(Connect(handlePlayerEvent));
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
        return {state:game.save(), log:savedLog, config:gameConfig, timeSaved:getUnixTime()};
    }

    private function handlePlayerEvent(player:Player, event:GameEvent):Void {

        if (!gameBegun)
            throw "Game has not begun!";

        var playerIndex:Int = players.indexOf(player);

        if (playerIndex == -1)
            throw "Player is not part of this game!";

        switch (event.type) {
            case PlayerAction(action, option):
                if (game.currentPlayer != playerIndex)
                    throw "Player " + playerIndex + " cannot act at this time!";
                game.chooseOption(action, option);
                if (game.winner >= 0) game.end(); // TEMPORARY
            case RefereeAction(action):
                throw "Player's can't send referee calls!";
            case Ready:
                readyCheck();
            case Error:
                throw "Player error: " + playerIndex;
        }

        event.player = playerIndex;
        event.timeReceived = getUnixTime();
        broadcastAndLog(event);
    }

    private function broadcastAndLog(event:GameEvent):Void {
        log.push(event);
        for (player in players) player.send(event.copy());
    }

    private function refereeCall(action:RefereeActionType):Void {
        broadcastAndLog({type:RefereeAction(action), timeIssued:getUnixTime()});
    }

    private function readyCheck():Void {
        if (allReady) return;
        for (player in players) if (!player.ready) return;
        allReady = true;
        refereeCall(AllReady);
    }

    private inline static function copyLog(source:Array<GameEvent>):Array<GameEvent> {
        return source.map(Reflect.copy).array();
    }

    private inline static function getUnixTime():Int {
        return Std.int(Date.now().getTime() / 1000);
    }

    private inline function getHasBegun():Bool { return game.hasBegun; }
}
