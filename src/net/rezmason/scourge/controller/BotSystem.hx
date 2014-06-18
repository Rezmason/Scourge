package net.rezmason.scourge.controller;

import haxe.Timer;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.Zig;

class BotSystem extends PlayerSystem {

    private var botsByIndex:Map<Int, BotPlayer>;
    private var botSignal:Zig<Int->GameEvent->Void>;
    private var ballots:Array<GameEvent>;
    private var numBots:Int;
    private var random:Void->Float;

    public function new(random:Void->Float):Void {
        super(true);

        botsByIndex = new Map();
        botSignal = new Zig();
        botSignal.add(onBotSignal);
        numBots = 0;
        this.random = random;
    }

    public function createPlayer(index:Int, playSignal:PlaySignal, smarts:Smarts, period:Int):Player {
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
            volley(bot, PlayerAction(Ready));
        }
    }

    override private function updateGame(actionIndex:Int, move:Int):Void {
        super.updateGame(actionIndex, move);
        for (bot in botsByIndex) volley(bot, PlayerAction(Synced));
    }

    override private function init(configData:String, saveData:String):Void {
        super.init(configData, saveData);
        for (bot in botsByIndex) if (bot.smarts != null) bot.smarts.init(game, config, bot.index, random);
    }

    override private function connect():Void beat(announceReady);
    override private function disconnect():Void endGame();
    override private function play():Void beat(choose);
    override private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && currentPlayer() != null;

    private function choose():Void {
        var playerSmarts:Smarts = botsByIndex[game.currentPlayer].smarts;
        var eventType:GameEventType = playerSmarts.choose();
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
