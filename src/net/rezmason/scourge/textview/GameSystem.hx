package net.rezmason.scourge.textview;

import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.StateChangeSequencer;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.textview.board.BoardBody;
import net.rezmason.scourge.textview.console.ConsoleUIMediator;

class GameSystem {

    public var referee(default, null):Referee;
    public var sequencer(default, null):StateChangeSequencer;
    public var boardBody(default, null):BoardBody;

    var console:ConsoleUIMediator;

    public function new(boardBody:BoardBody, console:ConsoleUIMediator):Void {
        referee = new Referee();
        sequencer = new StateChangeSequencer();
        
        this.boardBody = boardBody;
        this.console = console;

        sequencer.sequenceStartSignal.add(boardBody.presentStart);
        sequencer.sequenceUpdateSignal.add(boardBody.presentSequence);
    }

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, thinkPeriod:Int, animatePeriod:Int, isReplay:Bool, seed:UInt):Void {

        if (referee.gameBegun) referee.endGame();

        var playerDefs:Array<PlayerDef> = [];
        var randGen:Void->Float = lgm(seed);
        var randBot:Void->Float = lgm(seed);

        if (isReplay) {
            config = referee.lastGameConfig;
            var log:Array<GameEvent> = referee.lastGame.log.filter(playerActionsOnly);
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randGen = function() return floats.shift();
            while (playerDefs.length < config.numPlayers) {
                playerDefs.push(Bot(new ReplaySmarts(log), thinkPeriod + animatePeriod, randBot));
            }
        } else {
            while (playerDefs.length < config.numPlayers) {
                var char:String = playerPattern[playerDefs.length];
                var pdef = (char == 'b' ? Bot(new BasicSmarts(), thinkPeriod + animatePeriod, randBot) : Human);
                playerDefs.push(pdef);
            }
        }

        sequencer.setAnimationPeriod(animatePeriod);

        referee.beginGame({
            playerDefs:playerDefs,
            spectators:[sequencer],
            randGen:randGen,
            gameConfig:config
        });
    }

    function playerActionsOnly(event:GameEvent):Bool {
        var isPlayerAction:Bool = false;
        switch (event.type) {
            case PlayerAction(SubmitMove(action, move)): isPlayerAction = true;
            case _:
        }
        return isPlayerAction;
    }

    function lgm(n:UInt):Void->Float {
        return function() {
            n = (n * 0x41A7) % 0x7FFFFFFF;
            return n / 0x7FFFFFFF;
        }
    }
}
