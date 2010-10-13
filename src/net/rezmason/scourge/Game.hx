package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.Vector;
import flash.Lib;

class Game {
	
	inline static var DEAD:Int = 0;
	
	private var currentPiece:Int;
	private var currentAngle:Int;
	private var hat:Array<Int>;
	private var _numPlayers:Int;
	
	private var colorGrid:Vector<UInt>;
	private var freshGrid:Vector<UInt>;
	private var biteGrid:Vector<Bool>;
	private var bitmap:BitmapData;
	private var validPositionCache:Hash<Bool>;
	private var playerPool:Array<Player>;
	private var players:Array<Player>;
	private var currentPlayerIndex:Int;
	private var currentPlayer:Player;
	private var newElements:Array<Int>;
	private var bittenElements:Array<Int>;
	private var freshest:Int;
	
	private var stacks:Array<Array<Int>>;
	private var hStack:Array<Int>;
	private var vStack:Array<Int>;
	private var uStack:Array<Int>;
	private var dStack:Array<Int>;
	
	private var changeIncrements:Array<Int>;
	
	public function new() {
		// Set up data structure
		hat = [];
		colorGrid = new Vector<UInt>(Common.BOARD_NUM_CELLS);
		freshGrid = new Vector<UInt>(Common.BOARD_NUM_CELLS);
		biteGrid = new Vector<Bool>(Common.BOARD_NUM_CELLS);
		validPositionCache = new Hash();
		playerPool = [];
		players = [];
		newElements = [];
		bittenElements = [];
		hStack = [];
		vStack = [];
		uStack = [];
		dStack = [];
		stacks = [hStack, vStack, uStack, dStack]; // H, V, U, D
		changeIncrements = [1, Common.BOARD_SIZE, Common.BOARD_SIZE + 1, Common.BOARD_SIZE - 1];
		for (ike in 0...Common.MAX_PLAYERS) playerPool[ike] = new Player(ike + 1);
	}
	
	private function resetPieces():Void {
		var len:Int = Pieces.PIECES.length;
		for (ike in 0...len) hat.push(ike);
	}
	
	private function makePiece(?swap:Bool = false):Void {
		for (n in validPositionCache.keys()) validPositionCache.remove(n);
		if (!swap || hat.length == 0) resetPieces();
		var rand:Int;
		var currentBlocks:Array<Array<Int>> = Pieces.PIECES[currentPiece];
		do {
			rand = Std.int(Math.random() * hat.length);
		} while (Pieces.PIECES[hat[rand]] == currentBlocks);
		currentPiece = hat.splice(rand, 1)[0];
		currentAngle = Std.int(Math.random() * 4);
	}
	
	public function getPiece():Array<Int> {
		var cA:Int = currentAngle % Pieces.PIECES[currentPiece].length;
		return Pieces.PIECES[currentPiece][cA];
	}
	
	public function getPieceCenter():Array<Float> {
		var cA:Int = currentAngle % Pieces.CENTERS[currentPiece].length;
		return Pieces.CENTERS[currentPiece][cA];
	}
	
	public function getBiteGrid():Vector<Bool> {
		return biteGrid;
	}
	
	public function getBite():Array<Int> {
		return bittenElements;
	}
	
	private function rotatePiece(?cc:Bool):Array<Int> {
		for (n in validPositionCache.keys()) validPositionCache.remove(n);
		currentAngle += cc ? 1 : 3;
		currentAngle %= 4;
		var cA:Int = currentAngle % Pieces.PIECES[currentPiece].length;
		return Pieces.PIECES[currentPiece][cA];
	}
	
	public function getGrid():Vector<UInt> {
		return colorGrid.slice(0, Common.BOARD_NUM_CELLS);
	}
	
	public function getCurrentPlayer():Player {
		return currentPlayer;
	}
	
	public function getCurrentPlayerIndex():Int {
		return currentPlayerIndex;
	}
	
	public function getNumPlayers():Int {
		return _numPlayers;
	}
	
	public function getBiteRegion():Array<Bool> {
		var region:Array<Bool> = [];
		var wid:Int = Common.BOARD_SIZE;
		for (ike in 0...Common.BOARD_NUM_CELLS) {
			if (colorGrid[ike] == currentPlayer.id) {
				var valid:Bool = false;
				var x:Int = ike % wid;
				var y:Int = Std.int((ike - x) / wid);
				if ((x >  0	  && colorGrid[ike -   1] != 0 && colorGrid[ike -   1] != currentPlayer.id) ||
					(x <= wid && colorGrid[ike +   1] != 0 && colorGrid[ike +   1] != currentPlayer.id) ||
					(y >  0	  && colorGrid[ike - wid] != 0 && colorGrid[ike - wid] != currentPlayer.id) ||
					(y <= wid && colorGrid[ike + wid] != 0 && colorGrid[ike + wid] != currentPlayer.id)) {
					
					region[ike] = true;	
				}
			}
		}
		return region;
	}
	
	public function isPlayerAlive(index:Int):Bool {
		return players[index].alive;
	}
	
	public function processPlayerAction(?action:PlayerAction):Bool {
		if (action == null) action = PlayerAction.SKIP;
		switch (action) {
			case SKIP: 
				nextTurn();
				return true;
			case FORFEIT:
				colorGrid[currentPlayer.headIndex] = 0;
				killCheck();
				currentPlayer.alive = false;
				nextTurn();
				return true;
			case PLACE_PIECE(xCoord, yCoord): 
				return placePiece(xCoord, yCoord);
			case SWAP_PIECE:
				if (_numPlayers == 1 || currentPlayer.swaps > 0) {
					currentPlayer.swaps--;
					makePiece(true);
					return true;
				}
				return false;
			case SPIN_PIECE(cc):
				rotatePiece(cc);
				return true;
			/*
			case START_BITE(xCoord, yCoord):
				if (_numPlayers == 1 || currentPlayer.bites > 0) {
					currentPlayer.bites--;
					return startBite(xCoord, yCoord);
				}
				return false;
			case END_BITE(xCoord, yCoord):
				//if (!biting) return false;
				for (n in validPositionCache.keys()) validPositionCache.remove(n);
				return endBite(xCoord, yCoord);
			*/
		}
		return false;
	}
	
	public function evaluatePosition(x:Int, y:Int):Bool {
		var key:String = Std.string(x) + "|" + Std.string(y);
		
		// Maybe this position is cached.
		if (validPositionCache.exists(key)) return validPositionCache.get(key);
		
		var currentBlocks:Array<Int> = getPiece();
		var spotX:Int, spotY:Int, hasNeighbor:Bool;
		var ike:Int = 0;
		var m:Int = Common.BOARD_SIZE;
		
		// At first we assume that the position is invalid.
		validPositionCache.set(key, false);
		
		// easy tests for failure
		while (ike < currentBlocks.length) {
			spotX = x + currentBlocks[ike];
			spotY = y + currentBlocks[ike + 1];
			if (spotX < 0 || spotX >= m) return false; // off the grid
			if (spotY < 0 || spotY >= m) return false; // off the grid
			if (colorGrid[spotY * m + spotX] != DEAD) return false; // spot taken
			ike += 2;
		}
		
		// uglier fail tests
		hasNeighbor = false;
		ike = 0;
		while (ike < currentBlocks.length) {
			spotX = x + currentBlocks[ike];
			spotY = y + currentBlocks[ike + 1];
			hasNeighbor = hasNeighbor || (spotX - 1 >= 0 && colorGrid[(spotY + 0) * m + spotX - 1] == currentPlayer.id);
			hasNeighbor = hasNeighbor || (spotY - 1 >= 0 && colorGrid[(spotY - 1) * m + spotX + 0] == currentPlayer.id);
			hasNeighbor = hasNeighbor || (spotX + 1 <  m && colorGrid[(spotY + 0) * m + spotX + 1] == currentPlayer.id);
			hasNeighbor = hasNeighbor || (spotY + 1 <  m && colorGrid[(spotY + 1) * m + spotX + 0] == currentPlayer.id);
			ike += 2;
		}
		if (!hasNeighbor) return false; // not connected
		
		// The piece survived! This position is valid.
		validPositionCache.set(key, true);
		return true;
	}
	
	private function placePiece(x:Int, y:Int):Bool {
		if (!evaluatePosition(x, y)) return false;
		var currentBlocks:Array<Int> = getPiece();
		var spotX:Int, spotY:Int;
		var index:Int;
		var ike:Int = 0;
		while (ike < currentBlocks.length) {
			index = (y + currentBlocks[ike + 1]) * Common.BOARD_SIZE + x + currentBlocks[ike];
			// change current player's size
			newElements.push(index);
			ike += 2;
		}
		eatAlgorithm();
		killCheck();
		nextTurn();
		return true;
	}
	
	/*
	public function evaluateBite(xCoord:Int, yCoord:Int):Bool {
	
		bittenElements.splice(0, bittenElements.length);
		// Populate the bitten elements list
		// If an element's color is DEAD or the current player's color, stop
		
		return bittenElements.length > 0;
	}
	
	private function startBite(xCoord:Int, yCoord:Int):Bool {
		if (!evaluateBite(xCoord, yCoord)) return false;
		for (ike in 0...bittenElements.length) colorGrid[bittenElements[ike]] = DEAD;
		killCheck();
		return true;
	}
	*/
	
	private function eatAlgorithm():Void {	
		
		freshest = 1;
		
		for (ike in 0...Common.BOARD_NUM_CELLS) freshGrid[ike] = 0;
		
		processChangesIntoSlices(-1);
		
		var colorSlice:Array<UInt> = [];
		var freshSlice:Array<UInt> = [];
		var flatElements:Array<Int> = [];
		
		var stack:Array<Int>;
		var tail:Int, head:Int, changeIncrement:Int;
		var player:Player;
		
		var ike:Int, jen:Int, ken:Int;
		
		while (hStack.length + vStack.length + uStack.length + dStack.length > 0) {
			for (ike in 0...stacks.length) {
				stack = stacks[ike];
				changeIncrement = changeIncrements[ike];
				while (stack.length > 0) { // stack loop
					tail = stack.pop();
					head = stack.pop();
					jen = head;
					ken = 0;
					
					colorSlice.splice(0, colorSlice.length);
					freshSlice.splice(0, freshSlice.length);
					flatElements.splice(0, flatElements.length);
					
					while (jen != tail) {
						colorSlice[ken] = colorGrid[jen];
						freshSlice[ken] = freshGrid[jen];
						jen += changeIncrement;
						ken++;
					}
					
					linearEatAlgorithm(colorSlice, freshSlice, flatElements);
					for (jen in 0...flatElements.length) newElements.push(head + flatElements[jen] * changeIncrement);
					for (jen in 0...players.length) {
						player = players[jen];
						if (player.alive && inside(newElements, player.headIndex)) {
							player.alive = false;
							for (ken in 0...Common.BOARD_NUM_CELLS) if (colorGrid[ken] == player.id) newElements.push(ken);
						}
					}
					
					if (newElements.length > 0) processChangesIntoSlices(ike);
				}
			}
		}
	}
	
	private function processChangesIntoSlices(lastSliceKind:Int):Void {
		
		var index:Int;
		var cell:GridCell;
		var heads:Array<Int>;
		var tails:Array<Int>;
		var stack:Array<Int>;
		
		for (ike in 0...newElements.length) {
			
			index = newElements[ike];
			
			if (colorGrid[index] > 0) playerPool[colorGrid[index] - 1].size--;
			currentPlayer.size++;
			
			colorGrid[index] = currentPlayer.id;
			freshGrid[index] = freshest;
			
			cell = GridCell.get(index);
			heads = cell.heads;
			tails = cell.tails;
			
			for (jen in 0...4) {
				stack = stacks[jen];
				if (lastSliceKind != jen && !inside(stack, heads[jen], 2)) {
					stack.push(heads[jen]);
					stack.push(tails[jen]);
				}
			}
		}
		
		newElements.splice(0, newElements.length);
		freshest++;
	}
	
	private function linearEatAlgorithm(cSlice:Array<Int>, fSlice:Array<Int>, elementList:Array<Int>):Void {
		var first:Int = -2;
		for (ike in 0...cSlice.length) {
			if (cSlice[ike] == currentPlayer.id) {
				if (first != -2 && (fSlice[first] + fSlice[ike] > 0)) for (jen in first + 1...ike) elementList.push(jen);
				first = ike;
			} else if (cSlice[ike] == 0) {
				first = -2;
			}
		}
	}
	
	private function killCheck():Void {
		
		var data:BitmapData = new BitmapData(Common.BOARD_SIZE, Common.BOARD_SIZE, false, 0x0);
		data.setVector(data.rect, colorGrid);
		
		for (ike in 0...players.length) {
			var player:Player = players[ike];
			if (player.alive) player.alive = colorGrid[player.headIndex] != DEAD;
			if (player.alive) data.floodFill(player.headX, player.headY, 0x0);
		}
		
		var output:Vector<UInt> = data.getVector(data.rect);
		for (ike in 0...output.length) if (output[ike] & 0xF != 0) {
			// change current player's size
			colorGrid[ike] = DEAD;
		}
	}
	
	private function nextTurn():Void {
		var lastPlayer:Player = currentPlayer;
		// give some players some powerups if this is a deluxe game
		do {
			currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
			currentPlayer = players[currentPlayerIndex];
		} while (!currentPlayer.alive);
		
		makePiece();
		updateBiteGrid();
		
		if (_numPlayers > 1 && lastPlayer == currentPlayer) {
			// current player has won
		}
	}
	
	public function begin(?numPlayers:Int = 1, ?gameType:GameType):Void {
		_numPlayers = (numPlayers < 0) ? 1 : ((numPlayers > 4) ? 4 : numPlayers);
		if (gameType == null) gameType = GameType.CLASSIC;
		switch (gameType) {
			case CLASSIC:
			case DELUXE(startSwaps, startBites, timeLimit):
			case MAYHEM:
		}
		
		// Prime the grid
		for (ike in 0...Common.BOARD_NUM_CELLS) colorGrid[ike] = DEAD;
		var currentHeads:Array<Int> = Common.HEADS[_numPlayers - 1];
		players.splice(0, players.length);
		
		// Populate the player list
		for (ike in 0..._numPlayers) {
			var player:Player = playerPool[ike];
			players.push(player);
			player.bites = 10;
			player.swaps = 10;
			player.size = 1;
			player.headX = currentHeads[ike * 2];
			player.headY = currentHeads[ike * 2 + 1];
			player.headIndex = player.headY * Common.BOARD_SIZE + player.headX;
			player.alive = true;
			colorGrid[player.headIndex] = player.id;
		}
		
		// It's player 1's turn
		currentPlayerIndex = 0;
		currentPlayer = players[currentPlayerIndex];
		makePiece();
		updateBiteGrid();
	}
	
	private function updateBiteGrid():Void {
		var width:Int = Common.BOARD_SIZE;
		var index:Int;
		for (ike in 0...width) {
			for (jen in 0...width) {
				var worthy:Bool = false;
				index = ike * width + jen;
				if (colorGrid[index] == currentPlayer.id) {
					worthy = worthy || (jen >     0 && colorGrid[index -     1] > 0 && colorGrid[index - 1] != currentPlayer.id);
					worthy = worthy || (jen < width && colorGrid[index +     1] > 0 && colorGrid[index + 1] != currentPlayer.id);
					worthy = worthy || (ike >     0 && colorGrid[index - width] > 0 && colorGrid[index - 1] != currentPlayer.id);
					worthy = worthy || (ike < width && colorGrid[index + width] > 0 && colorGrid[index + 1] != currentPlayer.id);
				}
				biteGrid[index] = worthy;
			}
		}
	}
	
	private static function inside<T>(array:Array<T>, element:T, ?skip:Int):Bool {
		if (skip < 1) skip = 1;
		var ike:Int = 0;
		while (ike < array.length) {
			if (array[ike] == element) return true;	
			ike += skip;
		}
		return false;
	}
}