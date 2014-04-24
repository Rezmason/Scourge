package net.rezmason.scourge.textview;

import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.StateChangeSequencer;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;
import net.rezmason.scourge.textview.board.BoardBody;
import net.rezmason.scourge.textview.console.ConsoleUIMediator;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

class GameSystem {

    static var syncPeriod:Float = 1;
    static var movePeriod:Float = 10;

    public var referee(default, null):Referee;
    public var sequencer(default, null):StateChangeSequencer;
    public var boardBody(default, null):BoardBody;

    var console:ConsoleUIMediator;

    public function new(boardBody:BoardBody, console:ConsoleUIMediator):Void {
        referee = new Referee();
        sequencer = new StateChangeSequencer(syncPeriod, movePeriod);
        
        this.boardBody = boardBody;
        this.console = console;
    }

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, botPeriod:Int, isReplay:Bool):Void {

        if (referee.gameBegun) referee.endGame();
        //sequencer.viewSignal.removeAll();

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
            spectators:[sequencer],
            randGen:randGen,
            gameConfig:config,
            syncPeriod:syncPeriod,
            movePeriod:movePeriod,
        });

        //boardBody.attach(sequencer.getGame(), referee.numPlayers);
        //sequencer.viewSignal.add(boardBody.invalidateBoard);
        //sequencer.viewSignal.add(updateConsole);
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
