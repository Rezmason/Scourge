package net.rezmason.scourge.model.piece;

typedef PickPieceParams = {
    public var pieceTableIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
    public var pieces:Pieces;
}
