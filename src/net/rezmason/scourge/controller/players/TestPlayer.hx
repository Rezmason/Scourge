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
                    case AllReady:
                        play();
                    case Connect: connect();
                    case Disconnect: // Whatever
                    case Resume(savedState): resume(savedState);
                    case Save: // Whatever
                    case Init(config): init(config);
                    case RandomFloats(data): appendFloats(data);
                }
            case Ready: // Whatever!
        }
    }

    private function init(config:String):Void {
        trace("INIT " + index);
    }

    private function resume(savedState:String):Void {
        trace("RESUME " + index);

    }

    private function getReady():Void {
        ready = true;
        handler(this, {type:Ready, timeIssued:now()});
    }

    private function connect():Void {
        trace("CONNECT " + index);
        getReady();
    }

    private function play():Void {
        if (game.hasBegun) {
            trace("PLAY " + index);
            if (game.winner >= 0) game.end(); // TEMPORARY
            else if (game.currentPlayer == index) choose();
        }
    }

    private function appendFloats(input:String):Void {
        floats = floats.concat(Unserializer.run(input));
    }

    private function generateRandomFloat():Float {
        return floats.shift();
    }

    private function choose():Void {
        trace("CHOOSE " + index);
    }
}
