package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;
import net.rezmason.scourge.model.ScourgeConfig;

using Lambda;

class RandomSmarts extends Smarts {

    private var dropActionIndex:Int;
    private var swapActionIndex:Int;
    private var biteActionIndex:Int;
    private var quitActionIndex:Int;
    private var otherActionIndices:Array<Int>;
    private var canSkip:Bool;
    
    override public function init(game:Game, config:ScourgeConfig, id:Int, random:Void->Float):Void {
        super.init(game, config, id, random);
        dropActionIndex = game.actionIDs.indexOf(DROP_ACTION);
        swapActionIndex = game.actionIDs.indexOf(SWAP_ACTION);
        biteActionIndex = game.actionIDs.indexOf(BITE_ACTION);
        quitActionIndex = game.actionIDs.indexOf(QUIT_ACTION);
        canSkip = config.allowNowhereDrop;
    }

    override public function choose():GameEventType {
        var type:GameEventType = null;
        var rev:Int = game.revision;

        var dropMoves:Array<Move> = game.getMovesForAction(dropActionIndex);
        var choice:Int = 0;
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > (canSkip ? 1 : 0);
            if (canDrop) {
                choice = randIntRange(dropMoves.length - (canSkip ? 1 : 0));
                type = SubmitMove(rev, dropActionIndex, choice);
            }
        }

        if (type == null) {
            var swapMoves:Array<Move> = game.getMovesForAction(swapActionIndex);
            if (swapMoves.length > 0) {
                choice = randIntRange(swapMoves.length);
                type = SubmitMove(rev, swapActionIndex, choice);
            }
        }

        if (type == null) {
            var biteMoves:Array<Move> = game.getMovesForAction(biteActionIndex);
            if (biteMoves.length > 0) {
                choice = biteMoves.length - 1;
                type = SubmitMove(rev, biteActionIndex, choice);
            }
        }

        if (type == null) {
            if (canSkip) {
                type = SubmitMove(rev, dropActionIndex, choice);
            }
        }

        if (type == null) {
            var quitMoves:Array<Move> = game.getMovesForAction(quitActionIndex);
            if (quitMoves.length > 0) {
                type = SubmitMove(rev, quitActionIndex, choice);
            }
        }

        return type;
    }
}
