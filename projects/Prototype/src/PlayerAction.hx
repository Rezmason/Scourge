package;

enum PlayerAction {
	FORFEIT;
	SKIP;
	SWAP_PIECE;
	BITE(bSX:Int, bSY:Int, bEX:Int, bEY:Int);
	PLACE_PIECE(xCoord:Int, yCoord:Int, angle:Int);
}
