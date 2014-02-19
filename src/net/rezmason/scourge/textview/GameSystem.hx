package net.rezmason.scourge.textview;

import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.SimpleSpectator;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

using Lambda;

class GameSystem {

    static var syncPeriod:Float = 1;
    static var movePeriod:Float = 10;

    public var referee(default, null):Referee;
    public var spectator(default, null):SimpleSpectator;
    public var boardBody(default, null):BoardBody;

    public function new(boardBody:BoardBody):Void {
        referee = new Referee();
        spectator = new SimpleSpectator(syncPeriod, movePeriod);
        this.boardBody = boardBody;
    }

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, botPeriod:Int, isReplay:Bool):Void {

        if (referee.gameBegun) referee.endGame();
        spectator.viewSignal.removeAll();

        var playerDefs:Array<PlayerDef> = [];
        var randGen:Void->Float = randomFunction;

        if (isReplay) {
            config = referee.lastGameConfig;
            var log:Array<GameEvent> = referee.lastGame.log.filter(playerActionsOnly);
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randGen = function() return floats.shift();
            while (playerDefs.length < config.numPlayers) playerDefs.push(Bot(new ReplaySmarts(log), botPeriod));
        } else {
            while (playerDefs.length < config.numPlayers) {
                var char:String = playerPattern[playerDefs.length];
                var pdef = (char == 'b' ? Bot(new RandomSmarts(), botPeriod) : Human);
                playerDefs.push(pdef);
            }
        }

        referee.beginGame({
            playerDefs:playerDefs,
            spectators:[spectator],
            randGen:randGen,
            gameConfig:config,
            syncPeriod:syncPeriod,
            movePeriod:movePeriod,
        });

        boardBody.attach(spectator.getGame(), referee.numPlayers);
        spectator.viewSignal.add(boardBody.invalidateBoard);
    }

    function playerActionsOnly(event:GameEvent):Bool {
        var isPlayerAction:Bool = false;
        switch (event.type) {
            case PlayerAction(SubmitMove(action, move)): isPlayerAction = true;
            case _:
        }
        return isPlayerAction;
    }

    function randomFunction():Float {
        return Math.random();
        // return 0;
    }
}
