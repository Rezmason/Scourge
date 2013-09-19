package;

class Common {
	public static var MOST_BLOCKS_IN_PIECE:Int = 4;
	public static var PLAYER_DISTANCE:Float = 9;
	public static var BOARD_PADDING:Float = 5;
	public static var MAX_PLAYERS:Int = 8;
	public static var MAX_BITES:Int = 10;
	public static var MAX_SWAPS:Int = 10;
	public static var BITE_FREQUENCY:Int = 3;
	public static var SWAP_FREQUENCY:Int = 4;
	public static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ];
}

typedef GameOptions = {
	var numPlayers(default, null):Int;
	var circular(default, null):Bool;
	var duration(default, null):Float;
}

enum GameType {
	CLASSIC;
	GENETIC;
}
