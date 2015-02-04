package net.rezmason.scourge.model.piece;

typedef DropPieceParams = {
    public var overlapSelf:Bool;
    public var pieceTableIDs:Array<Int>;
    public var allowFlipping:Bool;
    public var allowRotating:Bool;
    public var growGraph:Bool;
    public var allowNowhere:Bool;
    public var allowPiecePick:Bool; // if true, nothing in the game itself is left to chance
    public var orthoOnly:Bool;
    public var diagOnly:Bool;
    public var pieces:Pieces;
}
