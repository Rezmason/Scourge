package model;

class GameState {

	public var currentPiece:Int;
	public var numPlayers:Int;
	public var numAlivePlayers:Int;
	public var bodyGrid:Array<Int>;
	public var maskGrid:Array<Int>;
	public var freshGrid:Array<Int>;
	public var legalMoveGrids:Array<Array<Bool>>;
	public var legalBiteGrid:Array<Array<Int>>;
	public var lifeGrid:Array<Int>;
	public var players:Array<Player>;
	public var currentPlayerIndex:Int;
	public var currentPlayer:Player;
	public var freshness:Int;
	public var turnItr:Int;
	public var turnCount:Int;

	public var boardSize:Int;
	public var boardNumCells:Int;
	public var boardNumMaskedCells:Int;
	public var changeIncrements:Array<Int>;
	public var gridCellMap:GridCellMap;

	public function new():Void {
		//maskGrid = [];
		bodyGrid = [];
		freshGrid = [];
		legalBiteGrid = [];
		lifeGrid = [];
		legalMoveGrids = [];
		players = [];
	}

	public static function copy(gameState:GameState):GameState {
		var clone:GameState = new GameState();

		clone.currentPiece = gameState.currentPiece;
		clone.numPlayers = gameState.numPlayers;
		clone.numAlivePlayers = gameState.numAlivePlayers;
		clone.bodyGrid = gameState.bodyGrid.copy();
		if (gameState.maskGrid != null) clone.maskGrid = gameState.maskGrid.copy();
		clone.freshGrid = gameState.freshGrid.copy();
		clone.legalMoveGrids = [];
		for (ike in 0...gameState.legalMoveGrids.length) {
			if (gameState.legalMoveGrids[ike] != null) clone.legalMoveGrids[ike] = gameState.legalMoveGrids[ike].copy();
		}
		clone.legalBiteGrid = [];
		for (ike in 0...gameState.legalBiteGrid.length) {
			if (gameState.legalBiteGrid[ike] != null) clone.legalBiteGrid[ike] = gameState.legalBiteGrid[ike].copy();
		}
		clone.lifeGrid = gameState.lifeGrid.copy();
		clone.players = [];
		for (ike in 0...gameState.players.length) clone.players[ike] = Player.copy(gameState.players[ike]);
		clone.currentPlayerIndex = gameState.currentPlayerIndex;
		clone.currentPlayer = clone.players[clone.currentPlayerIndex];
		clone.freshness = gameState.freshness;
		clone.turnItr = gameState.turnItr;
		clone.turnCount = gameState.turnCount;

		// these don't change
		clone.boardSize = gameState.boardSize;
		clone.boardNumCells = gameState.boardNumCells;
		clone.boardNumMaskedCells = gameState.boardNumMaskedCells;
		clone.changeIncrements = gameState.changeIncrements;
		clone.gridCellMap = gameState.gridCellMap;

		return clone;
	}
}
