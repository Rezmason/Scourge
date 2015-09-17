package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Actor;

import net.rezmason.scourge.game.piece.PieceAspect;
import net.rezmason.praxis.aspect.PlyAspect;

class SwapPieceActor extends Actor<SwapPieceParams> {

    @player(SwapAspect.NUM_SWAPS, true) var numSwaps_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;
    @global(PieceAspect.PIECE_TABLE_ID, true) var pieceTableID_;

    override public function prime():Void {
        for (player in eachPlayer()) player[numSwaps_] = params.startingSwaps;
    }

    override public function chooseMove(_):Void {
        var currentPlayer:Int = state.global[currentPlayer_];
        var numSwaps:Int = getPlayer(currentPlayer)[numSwaps_];
        getPlayer(currentPlayer)[numSwaps_] = numSwaps - 1;
        state.global[pieceTableID_] = NULL;
        signalChange();
    }
}

