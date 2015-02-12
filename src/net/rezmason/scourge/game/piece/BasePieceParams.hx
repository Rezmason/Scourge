package net.rezmason.scourge.game.piece;

typedef BasePieceParams = {
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var pieceTableIDs:Array<Int>; // The list of pieces available at any point in the game
    public var pieces:Pieces;
}
