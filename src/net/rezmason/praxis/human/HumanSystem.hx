package net.rezmason.praxis.human;

import net.rezmason.praxis.config.GameConfig;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.utils.Zig;

typedef Human = {};

class HumanSystem extends PlayerSystem {

    var humansByIndex:Map<Int, Human> = new Map();
    
    public var gameBegunSignal(default, null):Zig<GameConfig<Dynamic, Dynamic>->Game->Void> = new Zig();
    public var gameEndedSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveStartSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
    public var moveStopSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveStepSignal(default, null):Zig<String->Void> = new Zig();
    
    public var enableUISignal(default, null):Zig<Void->Void> = new Zig();

    public function new():Void super(false);
    public function createPlayer(index:Int) humansByIndex[index] = {};
    
    public function submitMove(turn, actionID, move):Void {
        if (turn != game.revision) throw 'Move submitted out of turn.';
        playSignal.dispatch(SubmitMove(turn, actionID, move));
    }

    override public function processGameEvent(type:GameEvent):Void {
        switch (type) {
            case SubmitMove(turn, action, move):
                if (turn == game.revision) {
                    moveStartSignal.dispatch(game.currentPlayer, action, move);
                    isGameUpdating = true;
                    if (game.hasBegun) updateGame(action, move);
                    isGameUpdating = false;
                    moveStopSignal.dispatch();
                }
            case Init(configData, saveData): 
                if (!game.hasBegun) {
                    init(configData, saveData);
                    gameBegunSignal.dispatch(config, game);
                }
            case Proceed(_):
                if (isMyTurn()) play();
            case End: 
                if (game.hasBegun) {
                    gameEndedSignal.dispatch();
                    game.end();
                }
            case Time(_):
        }
    }

    override function onMoveStep(cause:String):Void if (isGameUpdating) moveStepSignal.dispatch(cause);
    override function play():Void enableUISignal.dispatch();
    override function isMyTurn():Bool return game.hasBegun && game.winner < 0 && currentPlayer() != null;
    inline function currentPlayer():Human return humansByIndex[game.currentPlayer];
}
