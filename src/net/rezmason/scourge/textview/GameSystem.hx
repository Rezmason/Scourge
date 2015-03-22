package net.rezmason.scourge.textview;

import net.rezmason.ecce.Ecce;
import net.rezmason.praxis.bot.BotSystem;
import net.rezmason.praxis.bot.ReplaySmarts;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.praxis.play.Referee;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.Sequencer;
import net.rezmason.scourge.controller.RulePresenter;
import net.rezmason.scourge.game.ScourgeConfig;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.board.BoardAnimator;
import net.rezmason.scourge.textview.board.BoardInitializer;

class GameSystem {

    public var board(default, null):Body = new Body();
    public var hasLastGame(get, never):Bool;
    var referee:Referee = new Referee();
    var ecce:Ecce = new Ecce();

    public function new():Void {}

    public function beginGame(config:ScourgeConfig, playerPattern:Array<String>, thinkPeriod:Int, animateMils:Int, isReplay:Bool, seed:UInt):Void {

        if (referee.gameBegun) {
            referee.endGame();
        }

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
            config = cast referee.lastGameConfig;
            var floats:Array<Float> = referee.lastGame.floatsLog.copy();
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
        
        var rulePresenter:RulePresenter = Type.createInstance(config.fallbackRP, []);
        sequencer.gameStartSignal.add(rulePresenter.init);
        sequencer.boardChangeSignal.add(rulePresenter.presentBoardChange);
        
        var boardInitializer:BoardInitializer = new BoardInitializer(ecce, board);
        sequencer.gameStartSignal.add(function(_, _) boardInitializer.init());

        var boardAnimator:BoardAnimator = new BoardAnimator(ecce, board, animateMils);
        sequencer.moveSequencedSignal.add(boardAnimator.wake);
        boardAnimator.animCompleteSignal.add(sequencer.proceed);

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
