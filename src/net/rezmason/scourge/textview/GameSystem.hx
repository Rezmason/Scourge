package net.rezmason.scourge.textview;

import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.BotSystem;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.controller.IPlayer;
import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.StateChangeSequencer;
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
        boardBody.setProceedSignal(sequencer.proceedSignal);
    }

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, thinkPeriod:Int, animateMils:Int, isReplay:Bool, seed:UInt):Void {

        if (referee.gameBegun) referee.endGame();

        boardBody.setAnimationSpeed(animateMils);

        var playerDefs:Array<PlayerDef> = [];
        var randGen:Void->Float = lgm(seed);
        var randBot:Void->Float = lgm(seed);
        var botSystem:BotSystem = null;

        var hasHumans:Bool = false;
        var hasBots:Bool = false;

        if (isReplay) {
            config = referee.lastGameConfig;
            var log:Array<GameEvent> = referee.lastGame.log.filter(playerActionsOnly);
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randGen = function() return floats.shift();
            hasBots = true;
            for (ike in 0...config.numPlayers) {
                playerDefs.push(Bot(new ReplaySmarts(log), thinkPeriod));
            }
        } else {
            while (playerDefs.length < config.numPlayers) {
                var pdef:PlayerDef = null;
                var char:String = playerPattern[playerDefs.length];
                switch (char) {
                    case 'b':
                        pdef = Bot(new BasicSmarts(), thinkPeriod);
                        hasBots = true;
                }
                playerDefs.push(pdef);
            }
        }

        if (hasBots) botSystem = new BotSystem(randBot); // TODO: make bot system persistent

        if (hasBots) {
            botSystem.setMediator(sequencer);
        } else if (hasHumans) {
            // attach 
        }

        var players:Array<IPlayer> = makePlayers(playerDefs, botSystem);

        referee.beginGame({
            players:players,
            randGen:randGen,
            gameConfig:config
        });
    }

    function makePlayers(defs:Array<PlayerDef>, botSystem:BotSystem):Array<IPlayer> {
        var players:Array<IPlayer> = [];
        for (ike in 0...defs.length) {
            var def:PlayerDef = defs[ike];

            var player:IPlayer = null;
            switch (def) {
                case Bot(smarts, period): player = botSystem.createPlayer(ike, smarts, period);
                // case Human:
                // case Remote:
                case _: throw 'Unsupported player type "$def"';
            }

            players.push(player);
        }
        return players;
    }

    function playerActionsOnly(event:GameEvent):Bool {
        var isPlayerAction:Bool = false;
        switch (event.type) {
            case PlayerAction(SubmitMove(turn, action, move)): isPlayerAction = true;
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
