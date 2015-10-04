package net.rezmason.scourge.textview.errands;

import net.rezmason.ecce.Ecce;
import net.rezmason.praxis.bot.BotSystem;
import net.rezmason.praxis.bot.ReplaySmarts;
import net.rezmason.praxis.human.HumanSystem;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.praxis.play.Referee;
import net.rezmason.scourge.controller.BasicSmarts;
import net.rezmason.scourge.controller.MoveMediator;
import net.rezmason.scourge.controller.Sequencer;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.utils.Errand;
import net.rezmason.utils.santa.Present;

class BeginGameErrand extends Errand<Bool->String->Void> {

    var config:GameConfig<Dynamic, Dynamic>;
    var playerPattern:Array<String>;
    var thinkPeriod:Int;
    var animationLength:Float;
    var isReplay:Bool;
    var seed:UInt;

    public function new(config:GameConfig<Dynamic, Dynamic>, playerPattern:Array<String>, thinkPeriod:Int, animationLength:Float, isReplay:Bool, seed:UInt):Void {
        this.config = config;
        this.playerPattern = playerPattern;
        this.thinkPeriod = thinkPeriod;
        this.animationLength = animationLength;
        this.isReplay = isReplay;
        this.seed = seed;
    }

    override public function run():Void {

        var referee:Referee = new Present(Referee);
        var ecce:Ecce = new Present(Ecce);
        var sequencer:Sequencer = new Present(Sequencer);
        var moveMediator:MoveMediator = new Present(MoveMediator);

        if (referee.gameBegun) referee.endGame();
        for (e in ecce.get()) ecce.collect(e);
        moveMediator.moveChosenSignal.removeAll(); // TODO: move to MoveMediator
        
        var randGen:Void->Float = lgm(seed);
        var randBot:Void->Float = lgm(seed); // TODO: seed should only be given to *internal* bots
        var botSystem:BotSystem = new BotSystem(randBot); // TODO: recycle
        var humanSystem:HumanSystem = new HumanSystem(); // TODO: recycle

        moveMediator.moveChosenSignal.add(humanSystem.submitMove);
        humanSystem.enableUISignal.add(moveMediator.enableHumanMoves);
        
        if (isReplay) {
            config = referee.lastGameConfig;
            if (config == null) {
                onComplete.dispatch(false, 'Referee has no last game to replay.');
                return;
            }
            var floats:Array<Float> = referee.lastGame.floatsLog.copy();
            randGen = function() return floats.shift();
        }

        for (ike in 0...playerPattern.length) {
            switch (playerPattern[ike]) {
                case 'h':
                    humanSystem.createPlayer(ike);
                case 'b': 
                    var smarts = isReplay ? new ReplaySmarts(referee.lastGame.log) : new BasicSmarts();
                    botSystem.createPlayer(ike, smarts, thinkPeriod);
            }
        }

        referee.gameEventSignal.add(botSystem.processGameEvent);
        botSystem.playSignal.add(referee.submitMove);
        referee.gameEventSignal.add(humanSystem.processGameEvent);
        humanSystem.playSignal.add(referee.submitMove);

        sequencer.animationLength = animationLength;
        sequencer.connect(humanSystem);
        referee.beginGame(randGen, config);
        
        onComplete.dispatch(true, null);
    }

    function lgm(n:UInt):Void->Float {
        var a:UInt = 0x41A7;
        var div:UInt = 0x7FFFFFFF;
        return function() {
            n = (n * a) % div;
            return n / div;
        }
    }
}
