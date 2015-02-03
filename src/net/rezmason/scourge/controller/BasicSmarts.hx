package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;
import net.rezmason.scourge.model.ScourgeConfig;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.piece.DropPieceRule.DropPieceMove;
import net.rezmason.ropes.Aspect.*;

using net.rezmason.ropes.GridUtils;

class BasicSmarts extends Smarts {

    private var dropActionIndex:Int;
    private var swapActionIndex:Int;
    private var biteActionIndex:Int;
    private var quitActionIndex:Int;
    private var otherActionIndices:Array<Int>;
    private var canSkip:Bool;

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    
    override public function init(game:Game, config:ScourgeConfig, id:Int, random:Void->Float):Void {
        super.init(game, config, id, random);
        dropActionIndex = game.actionIDs.indexOf(DROP_ACTION);
        swapActionIndex = game.actionIDs.indexOf(SWAP_ACTION);
        biteActionIndex = game.actionIDs.indexOf(BITE_ACTION);
        quitActionIndex = game.actionIDs.indexOf(QUIT_ACTION);
        canSkip = config.allowNowhereDrop;

        occupier_ = game.plan.onNode(OwnershipAspect.OCCUPIER);
        isFilled_ = game.plan.onNode(OwnershipAspect.IS_FILLED);
    }

    override public function choose():GameEvent {
        var type:GameEvent = null;
        var rev:Int = game.revision;
        
        var dropMoves:Array<Move> = game.getMovesForAction(dropActionIndex);
        var choice:Int = 0;
        var numSkipMoves:Int = canSkip ? 1 : 0;
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > numSkipMoves;
            if (canDrop) {
                var prunedMoves:Array<Int> = pruneMoves(dropMoves, dropMoveHugsEdges);
                if (dropMoves.length - numSkipMoves > 15) {
                    choice = numSkipMoves + prunedMoves[randIntRange(prunedMoves.length)];
                } else {
                    choice = findBestMoveIndex(dropActionIndex, prunedMoves.iterator(), getSizeDelta);
                }
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
                // pruning
                var biteSizes:Array<Int> = biteMoves.map(function(_) return (cast _).bitNodes.length);
                var maxBiteSize:Int = biteSizes[biteSizes.length - 1];
                var maxBiteSizeIndex:Int = biteSizes.indexOf(maxBiteSize);
                
                choice = findBestMoveIndex(biteActionIndex, maxBiteSizeIndex...biteMoves.length, getSizeDelta);
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

    function getSizeDelta():Int {
        var sum:Int = 0;
        for (ike in 0...game.state.players.length) {
            if (ike == id) sum -= game.state.players[ike][totalArea_];
            else sum += game.state.players[ike][totalArea_];
        }
        return sum;
    }

    function dropMoveHugsEdges(move:Move):Bool {
        var dropMove:DropPieceMove = cast move;
        if (dropMove.addedNodes.length == 0) return false;
        for (nodeID in dropMove.addedNodes) {
            for (neighborLocus in game.state.loci[nodeID].orthoNeighbors()) {
                if (neighborLocus.value[isFilled_] == TRUE && neighborLocus.value[occupier_] == NULL) {
                    return true;
                }
            }
        }
        return false;
    }

    function pruneMoves(moves:Array<Move>, eval:Move->Bool):Array<Int> {
        var prunedIndices:Array<Int> = [];
        for (index in 0...moves.length) if (eval(moves[index])) prunedIndices.push(index);
        if (prunedIndices.length == 0) for (index in 0...moves.length) prunedIndices.push(index);
        return prunedIndices;
    }

    function findBestMoveIndex(actionIndex:Int, itr:Iterator<Int>, eval:Void->Int):Int {
        var extreme:Null<Int> = null;
        var extremeIndex:Int = 0;
        var rev:Int = game.revision;
        while (itr.hasNext()) {
            var index:Int = itr.next();
            game.chooseMove(actionIndex, index);
            var value:Int = eval();
            game.rewind(rev);
            if (extreme == null || extreme > value) {
                extreme = value;
                extremeIndex = index;
            }
        }
        return extremeIndex;
    }
}
