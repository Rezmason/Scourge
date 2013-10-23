package net.rezmason.scourge.controller;

import haxe.Timer;
import msignal.Signal;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.ScourgeConfig;

class BotSystem extends PlayerSystem {

    private var botsByIndex:Map<Int, BotPlayer>;
    private var botSignal:Signal2<Int, GameEvent>;
    private var ballots:Array<GameEvent>;
    private var numBots:Int;

    public function new():Void {
        super();

        botsByIndex = new Map();
        botSignal = new Signal2();
        botSignal.add(onBotSignal);
        numBots = 0;
    }

    public function createPlayer(index:Int, playSignal:Signal2<Player, GameEvent>, smarts:Smarts, period:Int):Player {
        var bot:BotPlayer = new BotPlayer(botSignal, index, smarts, period);
        botsByIndex[index] = bot;
        this.playSignal = playSignal;
        numBots++;
        return bot;
    }

    private function onBotSignal(senderIndex:Int, event:GameEvent):Void {

        if (botsByIndex[senderIndex] == null) throw 'Illegal sender $senderIndex';

        if (ballots == null) ballots = [event];
        else ballots.push(event);

        if (ballots.length == numBots) {

            var lastBallot:GameEvent = ballots.pop();
            for (ballot in ballots) {
                if (ballot.timeIssued != lastBallot.timeIssued) throw 'Ballots do not have matching times issued';
                if (!Type.enumEq(ballot.type, lastBallot.type)) throw 'Ballots do not have matching types';
            }

            ballots.splice(0, ballots.length);

            processGameEventType(lastBallot.type);
        }
    }

    override private function announceReady():Void {
        for (bot in botsByIndex) {
            bot.ready = true;
            volley(bot, Ready);
        }
    }

    override private function init(config:ScourgeConfig):Void {
        super.init(config);
        for (bot in botsByIndex) if (bot.smarts != null) bot.smarts.init(game);
    }

    override private function resume(save:SavedGame):Void {
        super.resume(save);
        for (bot in botsByIndex) if (bot.smarts != null) bot.smarts.init(game);
    }

    override private function connect():Void beat(announceReady);
    override private function disconnect():Void endGame();
    override private function play():Void beat(choose);
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && currentPlayer() != null;

    private function choose():Void {
        var playerSmarts:Smarts = botsByIndex[game.currentPlayer].smarts;
        if (playerSmarts == null) playerSmarts = smarts;
        var eventType:GameEventType = playerSmarts.choose(game);
        // trace('${game.currentPlayer} $eventType');
        volley(currentPlayer(), eventType);
    }

    private function beat(cbk:Void->Void):Void {
        #if neko
            cbk();
        #else
            var period:Int = 10;
            if (game.hasBegun) period = botsByIndex[game.currentPlayer].period;
            var timer:Timer = new Timer(period);
            timer.run = onBeat.bind(timer, cbk);
        #end
    }

    private function onBeat(timer:Timer, cbk:Void->Void):Void {
        #if !neko
            timer.stop();
            if (game.hasBegun) cbk();
        #end
    }

    override private function currentPlayer():Player return botsByIndex[game.currentPlayer];
}
