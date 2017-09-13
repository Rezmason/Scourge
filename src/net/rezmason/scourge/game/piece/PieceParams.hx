package net.rezmason.scourge.game.piece;

typedef PieceParams = {
    > BasePieceParams,
    > DropPieceParams,
    > PickPieceParams,
    > SwapPieceParams,

    allowAllPieces:Bool,
    allowSwapping:Bool,
}
