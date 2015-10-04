package net.rezmason.praxis.play;

import haxe.Unserializer;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.utils.Zig;

class PlayerSystem {

    public var playSignal(default, null):Zig<GameEvent->Void> = new Zig();

    private var game:Game;
    private var config:GameConfig<Dynamic, Dynamic>;
    private var isGameUpdating:Bool = false;
    
    function new(cacheMoves:Bool):Void game = new Game(cacheMoves);

    public function processGameEvent(type:GameEvent):Void {
        switch (type) {
            case SubmitMove(turn, action, move):
                if (turn == game.revision) {
                    isGameUpdating = true;
                    if (game.hasBegun) updateGame(action, move);
                    isGameUpdating = false;
                }
            case Init(configData, saveData): if (!game.hasBegun) init(configData, saveData);
            case Proceed(_): if (isMyTurn()) play();
            case End: end();
            case Time(_):
        }
    }

    private function init(configData:String, saveData:String):Void {
        var savedState:SavedState = saveData != null ? Unserializer.run(saveData).state : null;
        config = Unserializer.run(configData);
        game.begin(config, onMoveStep, savedState);
    }

    private function onMoveStep(cause:String):Void {}
    private function updateGame(actionID:String, move:Int):Void game.chooseMove(actionID, move);
    private function end():Void if (game.hasBegun) game.end();
    private function play():Void throw "Override this.";

    private function isMyTurn():Bool {
        throw "Override this.";
        return false;
    }
}
