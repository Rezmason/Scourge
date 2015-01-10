package net.rezmason.scourge.textview;

import net.rezmason.ecce.Ecce;
import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.BotSystem;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.controller.IPlayer;
import net.rezmason.scourge.controller.PlayerSystem;
import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.textview.core.Body;

class GameSystem {

    public var board(default, null):Body = new Body();
    public var hasLastGame(get, never):Bool;
    var referee:Referee = new Referee();
    var ecce:Ecce = new Ecce();

    public function new():Void {}

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, thinkPeriod:Int, animateMils:Int, isReplay:Bool, seed:UInt):Void {

        if (referee.gameBegun) referee.endGame();

        var botType:BotType = Basic;
        var randGen:Void->Float = lgm(seed);
        var randBot:Void->Float = lgm(seed); // TODO: seed should only be given to *internal* bots
        var botSystem:BotSystem = null;
        var watchedSystem:PlayerSystem = null;
        var hasHumans:Bool = !isReplay && playerPattern.indexOf('h') != -1;
        var hasBots:Bool   =  isReplay || playerPattern.indexOf('b') != -1;

        if (hasHumans) {
            // TODO: create HumanSystem
            // TODO: watchedSystem = humanSystem
        }

        if (hasBots) {
            botSystem = new BotSystem(!hasHumans, randBot); // TODO: recycle bot system
            if (watchedSystem == null) watchedSystem = botSystem;
        }

        if (isReplay) {
            config = referee.lastGameConfig;
            botType = Replay(referee.lastGame.log);
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randGen = function() return floats.shift();
        }

        var players:Array<IPlayer> = [];
        for (ike in 0...playerPattern.length) {
            switch (playerPattern[ike]) {
                case 'h' if (hasHumans): throw 'Humans cannot play yet.';
                default: 
                    var smarts = switch (botType) {
                        case Basic: new BasicSmarts();
                        case Replay(log): new ReplaySmarts(log);
                    }
                    players.push(botSystem.createPlayer(ike, smarts, thinkPeriod));
            }
        }

        // TODO: connect to watched system's signals here
        var g = null;
        watchedSystem.gameBegunSignal.add(function(_) { g = _; trace('GAME START'); watchedSystem.proceed(); });
        watchedSystem.moveStartSignal.add(function(_, _, _) { trace('READ START'); });
        watchedSystem.moveStepSignal.add(function(_) { trace(_); });
        watchedSystem.moveStopSignal.add(function() { trace('READ STOP'); watchedSystem.proceed(); });
        watchedSystem.gameEndedSignal.add(function() {
            trace('GAME END'); 
            g = null;
            watchedSystem.gameBegunSignal.removeAll();
            watchedSystem.gameEndedSignal.removeAll();
            watchedSystem.moveStartSignal.removeAll();
            watchedSystem.moveStepSignal.removeAll();
            watchedSystem.moveStopSignal.removeAll();
        });

        referee.beginGame(players, randGen, config);
    }

    function lgm(n:UInt):Void->Float return function() return (n = (n * 0x41A7) % 0x7FFFFFFF) / 0x7FFFFFFF;

    function get_hasLastGame():Bool return referee.lastGame != null;
}
