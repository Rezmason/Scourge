package net.rezmason.scourge.game.piece;

typedef DropPieceParams = {
    public var allowSkipping:Bool;
    public var allowPiecePick:Bool; // if true, nothing in the game itself is left to chance
    public var dropDiagOnly:Bool;
    public var dropOrthoOnly:Bool;
    public var dropOverlapsSelf:Bool;
}
