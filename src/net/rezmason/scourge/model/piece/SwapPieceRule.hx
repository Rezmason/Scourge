package net.rezmason.scourge.model.piece;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.rule.BaseRule;

import net.rezmason.scourge.model.piece.PieceAspect;
import net.rezmason.ropes.aspect.PlyAspect;

using Lambda;

using net.rezmason.utils.Pointers;

class SwapPieceRule extends BaseRule<SwapPieceParams> {

    @player(SwapAspect.NUM_SWAPS) var numSwaps_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;
    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;

    override private function _prime():Void {
        for (player in eachPlayer()) player[numSwaps_] = params.startingSwaps;
    }

    // This rule basically zaps the current player's piece and takes away a swap.
    override private function _update():Void {
        moves = [];
        var currentPlayer:Int = state.global[currentPlayer_];
        var numSwaps:Int = getPlayer(currentPlayer)[numSwaps_];
        if (numSwaps > 0 && state.global[pieceTableID_] != NULL) moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
                var currentPlayer:Int = state.global[currentPlayer_];
        var numSwaps:Int = getPlayer(currentPlayer)[numSwaps_];
        getPlayer(currentPlayer)[numSwaps_] = numSwaps - 1;
        state.global[pieceTableID_] = NULL;
        signalChange();
    }
}

