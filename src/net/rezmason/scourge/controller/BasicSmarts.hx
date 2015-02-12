package net.rezmason.scourge.controller;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.praxis.PraxisTypes.Move;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.piece.DropPieceRule.DropPieceMove;

using net.rezmason.praxis.grid.GridUtils;

class BasicSmarts extends Smarts {

    static var dropActionID:String = 'drop';
    static var swapActionID:String = 'swap';
    static var biteActionID:String = 'bite';
    static var quitActionID:String = 'forfeit';

    private var otherActionIndices:Array<Int>;
    private var canSkip:Bool;

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    
    override public function init(game:Game, config:ScourgeConfig, id:Int, random:Void->Float):Void {
        super.init(game, config, id, random);
        canSkip = config.pieceParams.allowSkipping;

        occupier_ = game.plan.onNode(OwnershipAspect.OCCUPIER);
        isFilled_ = game.plan.onNode(OwnershipAspect.IS_FILLED);
    }

    override public function choose():GameEvent {
        var type:GameEvent = null;
        var rev:Int = game.revision;
        
        var dropMoves:Array<Move> = game.getMovesForAction(dropActionID);
        var choice:Int = 0;
        var numSkipMoves:Int = canSkip ? 1 : 0;
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > numSkipMoves;
            if (canDrop) {
                var prunedMoves:Array<Int> = pruneMoves(dropMoves, dropMoveHugsEdges);
                if (dropMoves.length - numSkipMoves > 15) {
                    choice = numSkipMoves + prunedMoves[randIntRange(prunedMoves.length)];
                } else {
                    choice = findBestMoveIndex(dropActionID, prunedMoves.iterator(), getSizeDelta);
                }
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
                // pruning
                var biteSizes:Array<Int> = biteMoves.map(function(_) return (cast _).bitNodes.length);
                var maxBiteSize:Int = biteSizes[biteSizes.length - 1];
                var maxBiteSizeIndex:Int = biteSizes.indexOf(maxBiteSize);
                
                choice = findBestMoveIndex(biteActionID, maxBiteSizeIndex...biteMoves.length, getSizeDelta);
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
        if (dropMove.addedNodes == null || dropMove.addedNodes.length == 0) return false;
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

    function findBestMoveIndex(actionID:String, itr:Iterator<Int>, eval:Void->Int):Int {
        var extreme:Null<Int> = null;
        var extremeIndex:Int = 0;
        var rev:Int = game.revision;
        while (itr.hasNext()) {
            var index:Int = itr.next();
            game.chooseMove(actionID, index);
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
