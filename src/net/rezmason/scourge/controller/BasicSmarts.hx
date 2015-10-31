package net.rezmason.scourge.controller;

import net.rezmason.praxis.PraxisTypes.Move;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.bot.Smarts;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.GameEvent;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.piece.DropPieceMove;
import net.rezmason.scourge.game.piece.PieceAspect;
import net.rezmason.scourge.game.BoardUtils;

using net.rezmason.grid.GridUtils;

class BasicSmarts extends Smarts {

    static var dropActionID:String = 'drop';
    static var swapActionID:String = 'swap';
    static var biteActionID:String = 'bite';
    static var pickActionID:String = 'pick';
    static var quitActionID:String = 'forfeit';

    private var canSkip:Bool;

    @global(PieceAspect.PIECE_TABLE_INDEX) var pieceTableIndex_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;
    
    override public function init(game:Game, config:GameConfig<Dynamic, Dynamic>, id:Int, random:Void->Float):Void {
        super.init(game, config, id, random);
        canSkip = config.params['piece'].allowSkipping;

        occupier_ = game.plan.onSpace(OwnershipAspect.OCCUPIER);
        isFilled_ = game.plan.onSpace(OwnershipAspect.IS_FILLED);
    }

    override public function choose():GameEvent {
        var type:GameEvent = null;
        var rev:Int = game.revision;
        
        var dropMoves:Array<Move> = game.getMovesForAction(dropActionID);
        var choice:Int = 0;
        var numSkipMoves:Int = canSkip ? 1 : 0;

        if (state.global[pieceTableIndex_] == NULL) {
            type = SubmitMove(rev, pickActionID, choice);
        }
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > numSkipMoves;
            if (canDrop) {
                var prunedMoveIDs:Array<Int> = pruneMoves(dropMoves, dropMoveHugsEdges);
                if (prunedMoveIDs.length > 15) {
                    choice = numSkipMoves + prunedMoveIDs[randIntRange(prunedMoveIDs.length)];
                } else {
                    choice = findBestMoveID(dropActionID, prunedMoveIDs.iterator(), getSizeDelta);
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
                var biteSizes:Array<Int> = biteMoves.map(function(_) return (cast _).bitSpaces.length);
                var maxBiteSize:Int = biteSizes[biteSizes.length - 1];
                var maxBiteSizeIndex:Int = biteSizes.indexOf(maxBiteSize);
                
                choice = findBestMoveID(biteActionID, maxBiteSizeIndex...biteMoves.length, getSizeDelta);
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
        if (dropMove.addedSpaces == null || dropMove.addedSpaces.length == 0) return false;
        for (spaceID in dropMove.addedSpaces) {
            for (neighborCell in game.state.getCell(spaceID).orthoNeighbors()) {
                if (neighborCell.value[isFilled_] == TRUE && neighborCell.value[occupier_] == NULL) {
                    return true;
                }
            }
        }
        return false;
    }

    function pruneMoves(moves:Array<Move>, eval:Move->Bool):Array<Int> {
        var goodMoveIDs:Array<Int> = [];
        for (move in moves) if (eval(move)) goodMoveIDs.push(move.id);
        if (goodMoveIDs.length == 0) for (move in moves) goodMoveIDs.push(move.id);
        return goodMoveIDs;
    }

    function findBestMoveID(actionID:String, itr:Iterator<Int>, eval:Void->Int):Int {
        var bestScore:Null<Int> = null;
        var bestMoveID:Int = 0;
        var rev:Int = game.revision;
        while (itr.hasNext()) {
            var moveID:Int = itr.next();
            game.chooseMove(actionID, moveID);
            var score:Int = eval();
            game.rewind(rev);
            if (bestScore == null || bestScore > score) {
                bestScore = score;
                bestMoveID = moveID;
            }
        }
        return bestMoveID;
    }

    function spitMoves(actionID, moves:Array<Move>, ?eval:Move->Dynamic):Void {
        trace('Current board:');
        trace(net.rezmason.scourge.game.BoardUtils.spitBoard(state, plan));
        trace('------');
        var rev:Int = game.revision;
        for (ike in 0...moves.length) {
            trace('Attempting move $ike (${moves[ike]}):');
            game.chooseMove(actionID, moves[ike].id);
            trace(BoardUtils.spitBoard(state, plan, true, (cast moves[ike]).addedSpaces));
            if (eval != null) trace(eval(moves[ike]));
            game.rewind(rev);
            trace('------');
        }
    }
}
