package net.rezmason.scourge;

class GameState {
	
	public var currentPiece:Int;
	public var pieceHat:Hat;
	public var numPlayers:Int;
	public var numAlivePlayers:Int;
	public var colorGrid:Array<Int>;
	public var freshGrid:Array<Int>;
	public var legalMoveGrids:Array<Array<Bool>>;
	public var legalBiteGrid:Array<Bool>;
	public var aliveGrid:Array<Bool>;
	public var players:Array<Player>;
	public var currentPlayerIndex:Int;
	public var currentPlayer:Player;
	public var freshness:Int;
	private var turnItr:Int;
	private var turnCount:Int;
	
	public function new():Void {
		pieceHat = new Hat(Pieces.PIECES.length, Pieces.PIECES);
		colorGrid = [];
		freshGrid = [];
		legalBiteGrid = [];
		aliveGrid = [];
		legalMoveGrids = [];
		players = [];
	}
	
	public static function copy(gameState:GameState):GameState {
		var clone:GameState = new GameState();
		
		clone.currentPiece = gameState.currentPiece;
		clone.pieceHat = Hat.copy(gameState.pieceHat);
		clone.numPlayers = gameState.numPlayers;
		clone.numAlivePlayers = gameState.numAlivePlayers;
		clone.colorGrid = gameState.colorGrid.copy();
		clone.freshGrid = gameState.freshGrid.copy();
		clone.legalMoveGrids = gameState.legalMoveGrids.copy();
		clone.legalBiteGrid = gameState.legalBiteGrid.copy();
		clone.aliveGrid = gameState.aliveGrid.copy();
		clone.players = gameState.players.copy();
		clone.currentPlayerIndex = gameState.currentPlayerIndex;
		clone.currentPlayer = Player.copy(gameState.currentPlayer);
		clone.freshness = gameState.freshness;
		clone.turnItr = gameState.turnItr;
		clone.turnCount = gameState.turnCount;
		
		return clone;
	}
}