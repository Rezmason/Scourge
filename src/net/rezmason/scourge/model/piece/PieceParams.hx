package net.rezmason.scourge.model.piece;

typedef PieceParams = {
    > BasePieceParams,
    > DropPieceParams,
    > PickPieceParams,
    > SwapPieceParams,

    ?allowAllPieces:Bool,
    ?allowSwapping:Bool,
}
