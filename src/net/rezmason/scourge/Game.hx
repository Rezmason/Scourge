package net.rezmason.scourge;

class Game {

	inline static var DEAD:Int = 0;

	private var currentPiece:Int;
	private var currentAngle:Int;
	private var pieceHat:Array<Int>;
	private var _numPlayers:Int;
	
	private var defaultGrid:Array<Dynamic>;
	private var colorGrid:Array<Int>;
	private var freshGrid:Array<Int>;
	private var biteGrid:Array<Bool>;
	private var aliveGrid:Array<Bool>;
	private var validPositionCache:Hash<Bool>;
	private var playerPool:Array<Player>;
	private var players:Array<Player>;
	private var currentPlayerIndex:Int;
	private var currentPlayer:Player;
	private var newElements:Array<Int>;
	private var freshness:Int;

	private var stacks:Array<Array<Int>>;
	private var hStack:Array<Int>;
	private var vStack:Array<Int>;
	private var uStack:Array<Int>;
	private var dStack:Array<Int>;
	private var validBiteEnds:Array<Int>;

	private var biteX:Int;
	private var biteY:Int;
	private var biteLimits:Array<Int>;

	private var changeIncrements:Array<Int>;

	public function new(?_defaultGrid:Array<Dynamic>) {
		defaultGrid = (_defaultGrid[0] == -1) ? null : _defaultGrid;
		// Set up data structure
		biteX = biteY = -1;
		pieceHat = [];
		colorGrid = [];
		freshGrid = [];
		biteGrid = [];
		aliveGrid = [];
		validPositionCache = new Hash();
		playerPool = [];
		players = [];
		newElements = [];
		hStack = [];
		vStack = [];
		uStack = [];
		dStack = [];
		validBiteEnds = [];
		stacks = [hStack, vStack, uStack, dStack]; // H, V, U, D
		changeIncrements = [1, Common.BOARD_SIZE, Common.BOARD_SIZE + 1, Common.BOARD_SIZE - 1];
		for (ike in 0...Common.MAX_PLAYERS) playerPool[ike] = new Player(ike + 1);
	}

	private function resetPieces():Void {
		var len:Int = Pieces.PIECES.length;
		for (ike in 0...len) pieceHat.push(ike);
	}

	private function makePiece(?swap:Bool = false):Void {
		for (n in validPositionCache.keys()) {
			validPositionCache.remove(n);
		}
		if (!swap || pieceHat.length == 0) resetPieces();
		var rand:Int;
		var currentBlocks:Array<Array<Int>> = Pieces.PIECES[currentPiece];
		do {
			rand = Std.int(Math.random() * pieceHat.length);
			} while (Pieces.PIECES[pieceHat[rand]] == currentBlocks);
		currentPiece = pieceHat.splice(rand, 1)[0];
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

	public function getBiteGrid():Array<Bool> {
		return biteGrid;
	}

	public function getBiteLimits():Array<Int> {
		return biteLimits;
		// TOP RIGHT BOTTOM LEFT
	}
	
	public function getRollCall():Array<Player> {
		// Order the players by their turn and by whether they are alive
		var returnVal:Array<Player> = [];
		for (ike in currentPlayerIndex...players.length) if (players[ike].alive) returnVal.push(players[ike]);
		for (ike in 0...currentPlayerIndex) if (players[ike].alive) returnVal.push(players[ike]);
		for (ike in 0...players.length) if (!players[ike].alive) returnVal.push(players[ike]);
		return returnVal;
	}

	private function rotatePiece(?cc:Bool):Array<Int> {
		for (ike in validPositionCache.keys()) validPositionCache.remove(ike);
		currentAngle += cc ? 1 : 3;
		currentAngle %= 4;
		var cA:Int = currentAngle % Pieces.PIECES[currentPiece].length;
		return Pieces.PIECES[currentPiece][cA];
	}

	public function getColorGrid():Array<Int> {
		return colorGrid.slice(0, Common.BOARD_NUM_CELLS);
	}
	
	public function getFreshGrid():Array<Int> {
		return freshGrid.slice(0, Common.BOARD_NUM_CELLS);
	}
	
	public function getMaxFreshness():Int {
		return freshness;
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
	
	public function getPlayers():Array<Player> {
		return players.copy();
	}
	
	public function processPlayerAction(?action:PlayerAction):Bool {
		if (action == null) action = PlayerAction.SKIP;
		switch (action) {
			case SKIP: 
				// If a player with no bites skips, they're probably desparate or the game got boring.
				if (currentPlayer.bites == 0 && currentPlayer.biteHat.pick() <= 1) currentPlayer.bites++;
				nextTurn();
				return true;
			case FORFEIT:
				colorGrid[currentPlayer.headIndex] = 0;
				resetFreshness();
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
			case START_BITE(xCoord, yCoord):
				return startBite(xCoord, yCoord);
			case END_BITE(xCoord, yCoord):
				return endBite(xCoord, yCoord);
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

	private function startBite(xCoord:Int, yCoord:Int):Bool {
		var m:Int = Common.BOARD_SIZE;
		var index:Int = yCoord * m + xCoord;
		if (!biteGrid[index] || currentPlayer.bites == 0) return false;

		// find the cardinal limits of the bite
		biteLimits = [0, 0, 0, 0];
		validBiteEnds.splice(0, validBiteEnds.length);
		var lim:Int = currentPlayer.biteSize + 1;

		var topDone:Bool = false;
		var rightDone:Bool = false;
		var bottomDone:Bool = false;
		var leftDone:Bool = false;
		var newIndex:Int;

		for (ike in 1...lim) {
			
			if (!topDone) {
				newIndex = index - ike * m;
				if (yCoord - ike    >= 0 && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.id) {
					biteLimits[0]--;
					validBiteEnds.push(index - ike * m);
				} else {
					topDone = true;
				}
			}
			
			if (!rightDone) {
				newIndex = index + ike;
				if (xCoord + ike < m && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.id) {
					biteLimits[1]++;
					validBiteEnds.push(index + ike);
				} else {
					rightDone = true;
				}
			}
			
			if (!bottomDone) {
				newIndex = index + ike * m;
				if (yCoord + ike < m && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.id) {
					biteLimits[2]++;
					validBiteEnds.push(index + ike * m);
				} else {
					bottomDone = true;
				}
			}
			
			if (!leftDone) {
				newIndex = index - ike;
				if (xCoord - ike    >= 0 && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.id) {
					biteLimits[3]--;
					validBiteEnds.push(index - ike);
				} else {
					leftDone = true;
				}
			}
			
			biteX = xCoord;
			biteY = yCoord;
				
		}
		return true;
	}

	private function endBite(xCoord:Int, yCoord:Int):Bool {
		if (biteX == -1 || biteY == -1) return false;

		var biteIndex:Int = biteY * Common.BOARD_SIZE + biteX;
		var index:Int = yCoord * Common.BOARD_SIZE + xCoord;

		// validate the bite
		var valid:Bool = false;
		for (ike in 0...validBiteEnds.length) {
			if (validBiteEnds[ike] == index) {
				valid = true;
				break;
			}
		}
		if (!valid) return false;
		
		resetFreshness();
		
		var step:Int = (xCoord == biteX) ? Common.BOARD_SIZE : 1;

		do {
			colorGrid[index] = DEAD;
			freshGrid[index] = freshness;
			if (index < biteIndex) {
				index += step;
			} else {
				index -= step;
			}
		} while (index != biteIndex);
		killCheck();
		biteX = biteY = -1;
		updateBiteGrid();
		currentPlayer.bites--;
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
		resetFreshness();
		eatAlgorithm();
		killCheck();
		nextTurn();
		return true;
	}
	
	private function resetFreshness():Void {
		freshness = 1;
		for (ike in 0...Common.BOARD_NUM_CELLS) freshGrid[ike] = 0;
	}
	
	private function eatAlgorithm():Void {	
		
		processChangesIntoSlices(-1);

		var colorSlice:Array<Int> = [];
		var freshSlice:Array<Int> = [];
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
			freshGrid[index] = freshness;

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
		freshness++;
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
		
		aliveGrid.splice(0, aliveGrid.length);
		aliveGrid[Common.BOARD_NUM_CELLS - 1] = false;
		
		// start with the living heads
		for (ike in 0...players.length) {
			var player:Player = players[ike];
			if (player.alive) player.alive = colorGrid[player.headIndex] != DEAD;
			if (player.alive) {
				newElements.push(player.headIndex);
				aliveGrid[player.headIndex] = true;
			}
		}
		
		var w:Int = Common.BOARD_SIZE;
		var ike:Int = 0;
		var num:Int = newElements.length;
		
		// throw neighbors into newElements
		while (ike < num) {
			var index:Int = newElements[ike];
			var yCoord:Int = Std.int(index / w);
			var xCoord:Int = index - (yCoord * w);
			var color:Int = colorGrid[index];
			var amt:Int;
			
			amt = index - 1;
			if (xCoord > 0     && !aliveGrid[amt] && color == colorGrid[amt]) {
				aliveGrid[amt] = true;
				newElements.push(amt);
				num++;
			}
			
			amt = index + 1;
			if (xCoord < w - 1 && !aliveGrid[amt] && color == colorGrid[amt]) {
				aliveGrid[amt] = true;
				newElements.push(amt);
				num++;
			}
			
			amt = index - w;
			if (yCoord > 0     && !aliveGrid[amt] && color == colorGrid[amt]) {
				aliveGrid[amt] = true;
				newElements.push(amt);
				num++;
			}
			
			amt = index + w;
			if (yCoord < w - 1 && !aliveGrid[amt] && color == colorGrid[amt]) {
				aliveGrid[amt] = true;
				newElements.push(amt);
				num++;
			}
			
			ike++;
		}
		
		// delete the cells that aren't flagged
		for (ike in 0...aliveGrid.length) {
			if (colorGrid[ike] == DEAD || aliveGrid[ike]) continue;
			playerPool[colorGrid[ike] - 1].size--;
			colorGrid[ike] = DEAD;
			freshGrid[ike] = freshness;
		}
		
		// resize the players
		for (ike in 0...players.length) {
			var player:Player = players[ike];
			if (player.alive) {
				if (player.size < 0.2 * Common.BOARD_NUM_CELLS) {
					player.biteSize = 1;
				} else if (player.size < 0.4 * Common.BOARD_NUM_CELLS) {
					player.biteSize = 2;
				} else {
					player.biteSize = 3;
				}
			}
		}
		
		newElements.splice(0, newElements.length);
	}

	private function nextTurn():Void {
		// give some players some powerups if this is a deluxe game
		
		if (currentPlayer.bites < Common.MAX_BITES && currentPlayer.biteHat.pick() <= 1) {
			currentPlayer.bites++;
		} else if (currentPlayer.swaps < Common.MAX_SWAPS && currentPlayer.swapHat.pick() <= 1) {
			currentPlayer.swaps++;
		}
		
		var lastPlayer:Player = currentPlayer;
		
		do {
			currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
			currentPlayer = players[currentPlayerIndex];
		} while (!currentPlayer.alive);
		
		makePiece();
		updateBiteGrid();
	}

	public function begin(?numPlayers:Int = 1, ?gameType:GameType):Void {
		_numPlayers = (numPlayers < 0) ? 1 : ((numPlayers > 4) ? 4 : numPlayers);
		if (gameType == null) gameType = GameType.CLASSIC;
		switch (gameType) {
			case CLASSIC:
			case DELUXE(firstSwaps, firstBites, timeLimit):
			case MAYHEM:
		}
		
		// Prime the grid
		if (defaultGrid == null) {
			for (ike in 0...Common.BOARD_NUM_CELLS) colorGrid[ike] = DEAD;
		}
		
		var currentHeads:Array<Int> = Common.HEAD_POSITIONS[_numPlayers - 1];
		players.splice(0, players.length);

		// Populate the player list
		for (ike in 0..._numPlayers) {
			var player:Player = playerPool[ike];
			players.push(player);
			player.bites = 2;
			player.swaps = 10;
			player.size = 1;
			player.biteSize = 1;
			player.headX = currentHeads[ike * 2];
			player.headY = currentHeads[ike * 2 + 1];
			player.headIndex = player.headY * Common.BOARD_SIZE + player.headX;
			player.alive = true;
			player.swapHat.fill();
			player.biteHat.fill();
			colorGrid[player.headIndex] = player.id;
		}
		
		// Prime the grid
		if (defaultGrid != null) {
			for (ike in 0..._numPlayers) playerPool[ike].size = 0;
			for (ike in 0...Common.BOARD_NUM_CELLS) {
				colorGrid[ike] = Std.int(defaultGrid[ike]);
				if (colorGrid[ike] > 0) playerPool[colorGrid[ike] - 1].size++;
			}
		}
		
		resetFreshness();
		killCheck();
		
		// It's player 1's turn
		currentPlayerIndex = 0;
		currentPlayer = players[currentPlayerIndex];
		makePiece();
		updateBiteGrid();
	}

	private function updateBiteGrid():Void {
		biteGrid.splice(0, biteGrid.length);
		var w:Int = Common.BOARD_SIZE;
		for (ike in 0...Common.BOARD_NUM_CELLS) {
			if (colorGrid[ike] == currentPlayer.id) {
				var valid:Bool = false;
				var x:Int = ike % w;
				var y:Int = Std.int((ike - x) / w);
				if ((x > 0 && colorGrid[ike - 1] != 0 && colorGrid[ike - 1] != currentPlayer.id) ||
					(x < w - 1 && colorGrid[ike + 1] != 0 && colorGrid[ike + 1] != currentPlayer.id) ||
					(y > 0 && colorGrid[ike - w] != 0 && colorGrid[ike - w] != currentPlayer.id) ||
					(y < w - 1 && colorGrid[ike + w] != 0 && colorGrid[ike + w] != currentPlayer.id)) {

					biteGrid[ike] = true;	
				}
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