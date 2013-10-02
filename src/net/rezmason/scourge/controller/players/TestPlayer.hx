package net.rezmason.scourge.controller.players;

import haxe.Unserializer;
import net.rezmason.ropes.Types.Move;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;

import net.rezmason.scourge.model.aspects.*;
import net.rezmason.ropes.Types;

using Lambda;
using net.rezmason.scourge.model.BoardUtils;

typedef TestHelper = Game->(Void->Void)->Dynamic;

class TestPlayer extends Player {

    var helper:TestHelper;
    var annotate:Bool;

    var dropIndex:Int;
    var pickIndex:Int;
    var quitIndex:Int;

    var swapIndex:Int;
    var biteIndex:Int;

    var indices:Array<Int>;

    var moves:Array<Array<Move>>;

    public function new(index:Int, config:PlayerConfig, handler:Player->GameEvent->Void, helper:TestHelper, annotate:Bool):Void {
        super(index, config, handler);
        this.helper = helper;
        this.annotate = annotate;
    }

    var floats:Array<Float>;

    override private function prime():Void {
        floats = [];
        //trace('PRIME');
    }

    override private function processEvent(event:GameEvent):Void {
        switch (event.type) {
            case PlayerAction(action, move):
                if (game.hasBegun) game.chooseMove(action, move);
                play();
            case RefereeAction(action):
                switch (action) {
                    case AllReady: play();
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

    private function init(config:ScourgeConfig):Void {
        //trace('INIT $index');
        game.begin(config, retrieveRandomFloat, annotate ? handleAnnotation : null);

        dropIndex = game.actionIDs.indexOf('dropAction');
        pickIndex = game.actionIDs.indexOf('pickAction');
        quitIndex = game.actionIDs.indexOf('quitAction');

        swapIndex = game.actionIDs.indexOf('swapAction');
        biteIndex = game.actionIDs.indexOf('biteAction');

        indices = [pickIndex, dropIndex, pickIndex, swapIndex, biteIndex, quitIndex];
    }

    private function resume(savedGame:SavedGame):Void {
        //trace('RESUME $index');
        game.begin(savedGame.config, retrieveRandomFloat, annotate ? handleAnnotation : null, savedGame.state);
    }

    private function getReady():Void {
        ready = true;
        volley(Ready);
    }

    private function connect():Void {
        //trace('CONNECT $index');
        delay(getReady);
    }

    private function disconnect():Void {
        //trace('DISCONNECT $index');
        if (game.hasBegun) game.end();
    }

    private function play():Void {
        //trace('PLAY $index');
        if (game.hasBegun) {
            if (game.winner >= 0) game.end(); // TEMPORARY
            else if (game.currentPlayer == index) delay(choose);
        }
    }

    private function appendFloats(moreFloats:Array<Float>):Void {
        floats = floats.concat(moreFloats);
    }

    private function retrieveRandomFloat():Float {
        return floats.shift();
    }

    private function choose():Void {
        moves = game.getMoves();
        for (index in indices) if (volleyRandomPlayerAction(index)) break;
    }

    private inline function volleyRandomPlayerAction(index:Int):Bool {
        var possible:Bool = index != -1 && moves[index].length > 0;
        if (possible) volley(PlayerAction(index, Std.random(moves[index].length)));
        return possible;
    }

    private function volley(eventType:GameEventType):Void {
        handler(this, {type:eventType, timeIssued:now()});
    }

    private inline function delay(func:Void->Void) {
        if (func != null && helper != null) helper(game, func);
    }

    private function handleAnnotation(sender:String):Void
    {
        //trace('${game.currentPlayer} : $sender \n ${game.spitBoard()}');
    }
}
