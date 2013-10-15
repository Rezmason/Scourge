package net.rezmason.scourge.controller.players;

import haxe.Unserializer;
import net.rezmason.ropes.Types.Move;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.UnixTime;

using Lambda;

typedef TestProxy = Game->(Void->Void)->Dynamic;

class TestPlayer implements Player {

    private var handler:Player->GameEvent->Void;
    private var game:Game;
    private var config:PlayerConfig;
    private var gameConfig:ScourgeConfig;
    private var floats:Array<Float>;

    private static var ACTIONS:Array<String> = [DROP_ACTION, SWAP_ACTION, BITE_ACTION, QUIT_ACTION];
    private var proxy:TestProxy;
    private var actionIndices:Array<Int>;
    private var moves:Array<Array<Move>>;

    public var index(default, null):Int;
    public var ready(default, null):Bool;

    public function new(index:Int, config:PlayerConfig, handler:Player->GameEvent->Void, proxy:TestProxy):Void {
        this.index = index;
        this.handler = handler;
        this.config = config;
        this.proxy = proxy;
        if (game == null) game = new Game();
        floats = [];
    }

    @:allow(net.rezmason.scourge.controller.Referee)
    private function send(event:GameEvent):Void {

        if (!ready && Type.enumConstructor(event.type) == 'PlayerAction') {
            throw 'This player is not yet ready!';
        }

        switch (event.type) {
            case PlayerAction(action, move):
                if (game.hasBegun) updateGame(action, move);
                if (isMyTurn()) play();
            case RefereeAction(action):
                switch (action) {
                    case AllReady: if (isMyTurn()) play();
                    case Connect: connect();
                    case Disconnect: disconnect();
                    case Init(data): init(Unserializer.run(data));
                    case RandomFloats(data): appendFloats(Unserializer.run(data));
                    case Resume(data): resume(Unserializer.run(data));
                    case Save:
                }
            case Ready:
        }
    }

    private function announceReady():Void {
        ready = true;
        volley(Ready);
    }

    private function init(config:ScourgeConfig):Void {
        game.begin(config, retrieveRandomFloat);
        populateActionIndices();
    }

    private function resume(save:SavedGame):Void {
        game.begin(save.config, retrieveRandomFloat, save.state);
        populateActionIndices();
    }

    private function endGame():Void {
        game.end();
        game = null;
    }

    private function connect():Void proxy(game, announceReady);
    private function disconnect():Void proxy(game, endGame);
    private function updateGame(actionIndex:Int, move:Int):Void game.chooseMove(actionIndex, move);
    private function play():Void proxy(game, choose);

    private function appendFloats(moreFloats:Array<Float>):Void floats = floats.concat(moreFloats);
    private function retrieveRandomFloat():Float return floats.shift();
    private function volley(eventType:GameEventType):Void handler(this, {type:eventType, timeIssued:now()});
    private function now():Int return UnixTime.now();
    private function isMyTurn():Bool return game.hasBegun && game.winner < 0 && game.currentPlayer == index;

    private function populateActionIndices():Void actionIndices = ACTIONS.map(game.actionIDs.indexOf);

    private function choose():Void {
        moves = game.getMoves();
        for (actionIndex in actionIndices) if (volleyRandomPlayerAction(actionIndex)) break;
    }

    private function volleyRandomPlayerAction(actionIndex:Int):Bool {
        var possible:Bool = actionIndex != -1 && moves[actionIndex].length > 0;
        if (possible) volley(PlayerAction(actionIndex, Std.random(moves[actionIndex].length)));
        return possible;
    }
}
