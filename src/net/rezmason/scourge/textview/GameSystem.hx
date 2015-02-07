package net.rezmason.scourge.textview;

import net.rezmason.ecce.Ecce;
import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.BotSystem;
import net.rezmason.scourge.controller.IPlayer;
import net.rezmason.scourge.controller.PlayerSystem;
import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.Sequencer;
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

        var randGen:Void->Float = lgm(seed);
        var randBot:Void->Float = lgm(seed); // TODO: seed should only be given to *internal* bots
        var botSystem:BotSystem = null;
        var watchedPlayer:PlayerSystem = null;
        var hasHumans:Bool = !isReplay && playerPattern.indexOf('h') != -1;
        var hasBots:Bool   =  isReplay || playerPattern.indexOf('b') != -1;

        if (hasHumans) {
            // TODO: create HumanSystem
            // TODO: watchedPlayer = humanSystem
        }

        if (hasBots) {
            botSystem = new BotSystem(!hasHumans, randBot); // TODO: recycle
            if (watchedPlayer == null) watchedPlayer = botSystem;
        }

        if (isReplay) {
            config = referee.lastGameConfig;
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randGen = function() return floats.shift();
        }

        var players:Array<IPlayer> = [];
        for (ike in 0...playerPattern.length) {
            switch (playerPattern[ike]) {
                case 'h' if (hasHumans): throw 'Humans cannot play yet.';
                default: 
                    var smarts = isReplay ? new ReplaySmarts(referee.lastGame.log) : new BasicSmarts();
                    players.push(botSystem.createPlayer(ike, smarts, thinkPeriod));
            }
        }

        // TODO: recycle
        var sequencer = new Sequencer(ecce);
        sequencer.connect(watchedPlayer);
        
        referee.beginGame(players, randGen, config);
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
