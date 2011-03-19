package net.rezmason.scourge;

class Common {
	public static var MOST_BLOCKS_IN_PIECE:Int = 4;
	public static var BOARD_SIZE:Int = 20;
	public static var BOARD_NUM_CELLS:Int = BOARD_SIZE * BOARD_SIZE;
	public static var MAX_PLAYERS:Int = 4;
	public static var MAX_BITES:Int = 10;
	public static var MAX_SWAPS:Int = 50;
	public static var BITE_FREQUENCY:Int = 3;
	public static var SWAP_FREQUENCY:Int = 4;
	public static var HEAD_POSITIONS:Array<Array<Int>> = [
		[ 9,  10, ], 
		[ 5, 14, 14,  5, ], 
		[ 5, 14,  9,  5,         14, 13, ], 
		[ 5, 14,  5,  5, 14,  5, 14, 14, ], 
	];
	
	public static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF];
}