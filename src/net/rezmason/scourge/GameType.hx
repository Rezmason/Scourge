package net.rezmason.scourge;

enum GameType {
	CLASSIC;
	DELUXE(?startSwaps:Int, ?startBites:Int, ?timeLimit:Float);
	MAYHEM;
}