package net.rezmason.scourge.textview;

import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.BotSystem;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.controller.IPlayer;
import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.textview.core.Body;

class GameSystem {

    public var board(default, null):Body = new Body();
    public var hasLastGame(get, never):Bool;
    var referee:Referee = new Referee();

    public function new():Void {}

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, thinkPeriod:Int, animateMils:Int, isReplay:Bool, seed:UInt):Void {

        if (referee.gameBegun) referee.endGame();

        var playerDefs:Array<PlayerDef> = [];
        var randGen:Void->Float = lgm(seed);
        var randBot:Void->Float = lgm(seed); // TODO: seed should only be given to *internal* bots
        var botSystem:BotSystem = null;

        var hasHumans:Bool = false;
        var hasBots:Bool = false;

        if (isReplay) {
            config = referee.lastGameConfig;
            var log:Array<GameEvent> = referee.lastGame.log.filter(playerActionsOnly);
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randGen = function() return floats.shift();
            hasBots = true;
            for (ike in 0...config.numPlayers) playerDefs.push(Bot(Replay(log), thinkPeriod));
        } else {
            while (playerDefs.length < config.numPlayers) {
                var pdef:PlayerDef = null;
                var char:String = playerPattern[playerDefs.length];
                switch (char) {
                    case 'b':
                        pdef = Bot(Basic, thinkPeriod);
                        hasBots = true;
                    case 'h':
                        pdef = Human;
                        hasHumans = true;
                }
                playerDefs.push(pdef);
            }
        }

        if (hasBots) {
            botSystem = new BotSystem(randBot); // TODO: recycle bot system
            // botSystem.setMediator(blerp); // TODO: listen for bot system's events here
        } else if (hasHumans) {
            // TODO: player move view connects here
        }

        var players:Array<IPlayer> = makePlayers(playerDefs, botSystem);
        referee.beginGame({players:players, randGen:randGen, gameConfig:config});
    }

    function makePlayers(defs:Array<PlayerDef>, botSystem:BotSystem):Array<IPlayer> {
        var players:Array<IPlayer> = [];
        for (ike in 0...defs.length) {
            var def:PlayerDef = defs[ike];

            var player:IPlayer = null;
            switch (def) {
                case Bot(braininess, period): 
                    var smarts = switch (braininess) {
                        case Basic: new BasicSmarts();
                        case Replay(log): new ReplaySmarts(log);
                    }
                    player = botSystem.createPlayer(ike, smarts, period);
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
        var a:UInt = 0x41A7;
        var div:UInt = 0x7FFFFFFF;
        return function() {
            n = (n * a) % div;
            return n / div;
        }
    }

    function get_hasLastGame():Bool return referee.lastGame != null;
}
