package net.rezmason.scourge.controller.players;

import haxe.Unserializer;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.ScourgeConfig;

using Lambda;
using net.rezmason.scourge.model.BoardUtils;

typedef TestHelper = (Void->Void)->Dynamic;

class TestPlayer extends Player {

    var helper:TestHelper;

    public function new(index:Int, config:PlayerConfig, handler:Player->GameEvent->Void, helper:TestHelper):Void {
        super(index, config, handler);
        this.helper = helper;
    }

    var floats:Array<Float>;

    override private function prime():Void {
        floats = [];
        //trace("PRIME");
    }

    override private function processEvent(event:GameEvent):Void {
        switch (event.type) {
            case PlayerAction(action, option):
                if (game.hasBegun) game.chooseOption(action, option);
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
        //trace("INIT " + index);
        game.begin(config, retrieveRandomFloat);
    }

    private function resume(savedGame:SavedGame):Void {
        //trace("RESUME " + index);
        game.begin(savedGame.config, retrieveRandomFloat, savedGame.state);
    }

    private function getReady():Void {
        ready = true;
        volley(Ready);
    }

    private function connect():Void {
        //trace("CONNECT " + index);
        delay(getReady);
    }

    private function disconnect():Void {
        //trace("DISCONNECT " + index);
        if (game.hasBegun) game.end();
    }

    private function play():Void {
        //trace("PLAY " + index);
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
        //trace("CHOOSE " + index);

        var dropIndex:Int = game.actionIDs.indexOf("dropAction");
        var firstDropOption:Int = game.getOptions()[dropIndex].length - 1;

        var pickPieceIndex:Int = game.actionIDs.indexOf("pickPieceAction");
        var firstPickPieceOption:Int = game.getOptions()[pickPieceIndex].length - 1;

        if (firstDropOption == 0 && firstPickPieceOption == 0) volley(PlayerAction(pickPieceIndex, firstPickPieceOption));
        else if (firstDropOption > 0) volley(PlayerAction(dropIndex, firstDropOption));
        else trace(["ERROR:", firstDropOption, firstPickPieceOption]);
    }

    private function volley(eventType:GameEventType):Void {
        handler(this, {type:eventType, timeIssued:now()});
    }

    private inline function delay(func:Void->Void) {
        if (func != null && helper != null) helper(func);
    }
}
