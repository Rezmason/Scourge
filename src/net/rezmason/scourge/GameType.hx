package net.rezmason.scourge;

enum GameType {
	CLASSIC;
	DELUXE(?firstSwaps:Int, ?firstBites:Int, ?timeLimit:Float);
	MAYHEM;
}