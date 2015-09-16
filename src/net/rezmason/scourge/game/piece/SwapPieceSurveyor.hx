package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Surveyor;

import net.rezmason.scourge.game.piece.PieceAspect;
import net.rezmason.praxis.aspect.PlyAspect;

class SwapPieceSurveyor extends Surveyor<SwapPieceParams> {

    @player(SwapAspect.NUM_SWAPS, true) var numSwaps_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;
    @global(PieceAspect.PIECE_TABLE_ID, true) var pieceTableID_;

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
}

