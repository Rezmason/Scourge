package net.rezmason.scourge;

enum PlayerAction {
	SKIP;
	FORFEIT;
	PLACE_PIECE(xCoord:Int, yCoord:Int);
	SWAP_PIECE;
	SPIN_PIECE(?cc:Bool);
	//START_BITE(xCoord:Int, yCoord:Int);
	//END_BITE(xCoord:Int, yCoord:Int);
}