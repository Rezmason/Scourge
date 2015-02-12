package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.ropes.play.Game;
import net.rezmason.ropes.play.GameEvent;
import net.rezmason.scourge.model.ScourgeConfig;

using Lambda;

class RandomSmarts extends Smarts {

    static var dropActionID:String = 'drop';
    static var swapActionID:String = 'swap';
    static var biteActionID:String = 'bite';
    static var quitActionID:String = 'forfeit';
    private var otherActionIndices:Array<Int>;
    private var canSkip:Bool;
    
    override public function init(game:Game, config:ScourgeConfig, id:Int, random:Void->Float):Void {
        super.init(game, config, id, random);
        dropActionID = 'drop';
        swapActionID = 'swap';
        biteActionID = 'bite';
        quitActionID = 'forfeit';
        canSkip = config.pieceParams.allowSkipping;
    }

    override public function choose():GameEvent {
        var type:GameEvent = null;
        var rev:Int = game.revision;

        var dropMoves:Array<Move> = game.getMovesForAction(dropActionID);
        var choice:Int = 0;
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > (canSkip ? 1 : 0);
            if (canDrop) {
                choice = randIntRange(dropMoves.length - (canSkip ? 1 : 0));
                type = SubmitMove(rev, dropActionID, choice);
            }
        }

        if (type == null) {
            var swapMoves:Array<Move> = game.getMovesForAction(swapActionID);
            if (swapMoves.length > 0) {
                choice = randIntRange(swapMoves.length);
                type = SubmitMove(rev, swapActionID, choice);
            }
        }

        if (type == null) {
            var biteMoves:Array<Move> = game.getMovesForAction(biteActionID);
            if (biteMoves.length > 0) {
                choice = biteMoves.length - 1;
                type = SubmitMove(rev, biteActionID, choice);
            }
        }

        if (type == null) {
            if (canSkip) {
                type = SubmitMove(rev, dropActionID, choice);
            }
        }

        if (type == null) {
            var quitMoves:Array<Move> = game.getMovesForAction(quitActionID);
            if (quitMoves.length > 0) {
                type = SubmitMove(rev, quitActionID, choice);
            }
        }

        return type;
    }
}
