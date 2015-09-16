package net.rezmason.scourge.game.piece;

typedef PickPieceParams = {
    >BasePieceParams, 
    hatSize:Int, // Number of pieces in the "hat" before it's refilled
    ?pieceMoves:Array<PickPieceMove>,
}
