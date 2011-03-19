package net.rezmason.scourge;

class Game {
	
	private var defaultGrid:Array<Dynamic>;
	
	private var g:GameState;
	private var allUniquePlayers:Array<Player>;
	private var allPlayerActions:Array<Dynamic>;
	
	// the game state
	private var currentPiece:Int;
	private var pieceHat:Hat;
	private var numPlayers:Int;
	private var numAlivePlayers:Int;
	private var colorGrid:Array<Int>;
	private var freshGrid:Array<Int>;
	private var legalMoveGrids:Array<Array<Bool>>;
	private var legalBiteGrid:Array<Array<Int>>;
	private var aliveGrid:Array<Bool>;
	private var players:Array<Player>;
	private var currentPlayerIndex:Int;
	private var currentPlayer:Player;
	private var freshness:Int;
	private var turnItr:Int;
	private var turnCount:Int;
	
	// specific to the eat algorithm
	private var eatStacks:Array<Array<Int>>;
	private var hStack:Array<Int>;
	private var vStack:Array<Int>;
	private var uStack:Array<Int>;
	private var dStack:Array<Int>;
	private var changeIncrements:Array<Int>;
	private var newElements:Array<Int>;

	public function new(?_defaultGrid:Array<Dynamic>) {
		defaultGrid = (_defaultGrid[0] == -1) ? null : _defaultGrid;
		// Set up data structure
		pieceHat = new Hat(Pieces.PIECES.length, Pieces.PIECES);
		colorGrid = [];
		freshGrid = [];
		legalBiteGrid = [];
		aliveGrid = [];
		allUniquePlayers = [];
		legalMoveGrids = [];
		players = [];
		newElements = [];
		hStack = [];
		vStack = [];
		uStack = [];
		dStack = [];
		eatStacks = [hStack, vStack, uStack, dStack]; // H, V, U, D
		changeIncrements = [1, Common.BOARD_SIZE, Common.BOARD_SIZE + 1, Common.BOARD_SIZE - 1];
		for (ike in 0...Common.MAX_PLAYERS) allUniquePlayers[ike] = new Player(ike + 1);
		fillTable(Pieces.PIECES);
		fillTable(Pieces.CENTERS);
		fillTable(Pieces.NEIGHBORS);
		allPlayerActions = [forfeit, endTurn, swapPiece, takeBite, placePiece];
	}
	
	
	public function begin(?_numPlayers:Int = 1, ?gameType:GameType):Void {
		numPlayers = (_numPlayers < 0) ? 1 : ((_numPlayers > 4) ? 4 : _numPlayers);
		numAlivePlayers = numPlayers;
		
		if (gameType == null) gameType = GameType.CLASSIC;
		
		switch (gameType) {
			case CLASSIC:
			case DELUXE(firstSwaps, firstBites, timeLimit):
			case MAYHEM:
		}
		
		// Prime the grid
		if (defaultGrid == null) for (ike in 0...Common.BOARD_NUM_CELLS) colorGrid[ike] = 0;
		
		var currentHeads:Array<Int> = Common.HEAD_POSITIONS[numPlayers - 1];
		players.splice(0, players.length);

		// Populate the player list
		for (ike in 0...numPlayers) {
			var player:Player = allUniquePlayers[ike];
			players.push(player);
			player.bites = 2;
			player.swaps = 10;
			player.size = 1;
			player.biteSize = 1;
			player.headX = currentHeads[ike * 2];
			player.headY = currentHeads[ike * 2 + 1];
			player.headIndex = player.headY * Common.BOARD_SIZE + player.headX;
			player.alive = true;
			colorGrid[player.headIndex] = player.uid;
		}
		
		// Prime the grid
		if (defaultGrid != null) {
			for (ike in 0...numPlayers) allUniquePlayers[ike].size = 0;
			for (ike in 0...Common.BOARD_NUM_CELLS) {
				colorGrid[ike] = Std.int(defaultGrid[ike]);
				if (colorGrid[ike] > 0) allUniquePlayers[colorGrid[ike] - 1].size++;
			}
		}
		
		resetFreshness();
		killCheck();
		
		// It's player 1's turn
		currentPlayerIndex = 0;
		turnItr = 0;
		turnCount = 0;
		currentPlayer = players[currentPlayerIndex];
		currentPiece = -1;
		makePiece();
		updateLegalBiteGrid();
	}
	
	public function getPiece():Array<Array<Int>> { return Pieces.PIECES[currentPiece]; }
	public function getPieceCenter():Array<Array<Float>> { return Pieces.CENTERS[currentPiece]; }
	public function getLegalBiteGrid():Array<Array<Int>> { return legalBiteGrid; }
	public function getColorGrid():Array<Int> { return colorGrid.copy(); }
	public function getFreshGrid():Array<Int> { return freshGrid.copy(); }
	public function getMaxFreshness():Int { return freshness; }
	public function getCurrentPlayer():Player { return currentPlayer; }
	public function getCurrentPlayerIndex():Int { return currentPlayerIndex; }
	public function getNumPlayers():Int { return numPlayers; }
	public function getPlayers():Array<Player> { return players.copy(); }
	public function testPosition(xCoord:Int, yCoord:Int, angle:Int):Bool { return legalMoveGrids[angle][yCoord * Common.BOARD_SIZE + xCoord]; }
	
	public function act(action:PlayerAction):Bool {
		return Reflect.callMethod(null, allPlayerActions[Type.enumIndex(action)], Type.enumParameters(action));
	}
	
	private function fillTable(table:Array<Array<Dynamic>>):Void {
		for (ike in 0...table.length) {
			var originalLength:Int = table[ike].length;
			var jen:Int = originalLength;
			while (jen < 4) {
				table[ike].push(table[ike][jen % originalLength]);
				jen++;
			}
		}
	}
	
	private function forfeit():Bool {
		colorGrid[currentPlayer.headIndex] = 0;
		resetFreshness();
		killCheck();
		currentPlayer.alive = false;
		numAlivePlayers--;
		return endTurn();
	}
	
	private function makePiece(?swap:Bool = false):Void {
		if (!swap) Hat.fill(pieceHat);
		currentPiece = Hat.pickMapped(pieceHat, false, Pieces.PIECES[currentPiece]);
		updateLegalMoveGrids();
	}
	
	private function updateLegalMoveGrids():Void {
		var pieceData:Array<Array<Int>> = Pieces.PIECES[currentPiece];
		var neighborData:Array<Array<Int>> = Pieces.NEIGHBORS[currentPiece];
		
		for (ike in 0...pieceData.length) {
			var currentBlocks:Array<Int> = pieceData[ike];
			var currentNeighbors:Array<Int> = neighborData[ike];
			if (legalMoveGrids[ike] == null) legalMoveGrids[ike] = [];
			var legalMoveGridForAngle:Array<Bool> = legalMoveGrids[ike];
			for (jen in 0...Common.BOARD_NUM_CELLS) legalMoveGridForAngle[jen] = testMoveLegality(jen, currentBlocks, currentNeighbors);
		}
	}
	
	private function testMoveLegality(index:Int, blocks:Array<Int>, neighbors:Array<Int>):Bool {
		var spotX:Int, spotY:Int;
		var w:Int = Common.BOARD_SIZE;
		var ike:Int;
		var yCoord:Int = Std.int(index / w);
		var xCoord:Int = index - (yCoord * w);
		
		// easy tests for failure
		ike = 0;
		while (ike < blocks.length) {
			spotX = xCoord + blocks[ike]; spotY = yCoord + blocks[ike + 1];
			if (spotX < 0 || spotX >= w) return false; // off the grid
			if (spotY < 0 || spotY >= w) return false; // off the grid
			if (colorGrid[spotY * w + spotX] != 0) return false; // spot taken
			ike += 2;
		}
		
		// neighbor test
		ike = 0;
		while (ike < neighbors.length) {
			spotX = xCoord + neighbors[ike]; spotY = yCoord + neighbors[ike + 1];
			if (colorGrid[spotY * w + spotX] == currentPlayer.uid) return true; // neighbor exists
			ike += 2;
		}
		
		return false;
	}
	
	private function swapPiece():Bool {
		if (numPlayers != 1 && currentPlayer.swaps <= 0) return false;
		currentPlayer.swaps--;
		makePiece(true);
		return true;
	}
	
	private function takeBite(startXCoord:Int, startYCoord:Int, endXCoord:Int, endYCoord:Int):Bool {
		if ((endXCoord != startXCoord) == (endYCoord != startYCoord)) return false;
		
		var startIndex:Int = startYCoord * Common.BOARD_SIZE + startXCoord;
		var endIndex  :Int = endYCoord   * Common.BOARD_SIZE + endXCoord;
		
		var biteLimits:Array<Int> = legalBiteGrid[startIndex];
		if (biteLimits == null) return false;
		
		var differences:Array<Int> = [endXCoord - startXCoord, endYCoord - startYCoord];
		var vertical:Int = (endXCoord == startXCoord) ? 1 : 0;
		if (differences[vertical] < biteLimits[vertical] || differences[vertical] > biteLimits[2 + vertical]) return false;
		
		resetFreshness();
		
		// clear the bite region
		
		var step:Int = (startXCoord == endXCoord) ? Common.BOARD_SIZE : 1;
		var index:Int = endIndex;
		do {
			colorGrid[index] = 0;
			freshGrid[index] = freshness;
			if (index < startIndex) {
				index += step;
			} else {
				index -= step;
			}
		} while (index != startIndex);
		
		
		killCheck();
		currentPlayer.bites--;
		updateLegalBiteGrid();
		updateLegalMoveGrids();
		return true;
	}

	private function placePiece(x:Int, y:Int, angle:Int):Bool {
		
		if (!testPosition(x, y, angle)) return false;
		
		resetFreshness();
		
		var currentBlocks:Array<Int> = getPiece()[angle];
		var spotX:Int, spotY:Int;
		var index:Int;
		var ike:Int = 0;
		while (ike < currentBlocks.length) {
			index = (y + currentBlocks[ike + 1]) * Common.BOARD_SIZE + x + currentBlocks[ike];
			// change current player's size
			newElements.push(index);
			ike += 2;
		}
		
		processChangesIntoSlices(-1);

		var colorSlice:Array<Int> = [];
		var freshSlice:Array<Int> = [];
		var flatElements:Array<Int> = [];

		var stack:Array<Int>;
		var tail:Int, head:Int, changeIncrement:Int;
		var player:Player;

		var ike:Int, jen:Int, ken:Int;

		while (hStack.length + vStack.length + uStack.length + dStack.length > 0) {
			for (ike in 0...eatStacks.length) {
				stack = eatStacks[ike];
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
							for (ken in 0...Common.BOARD_NUM_CELLS) if (colorGrid[ken] == player.uid) newElements.push(ken);
						}
					}

					if (newElements.length > 0) processChangesIntoSlices(ike);
				}
			}
		}
		
		killCheck();
		endTurn();
		return true;
	}
	
	private function resetFreshness():Void {
		freshness = 1;
		for (ike in 0...Common.BOARD_NUM_CELLS) freshGrid[ike] = 0;
	}
	
	private function processChangesIntoSlices(lastSliceKind:Int):Void {

		var index:Int;
		var cell:GridCell;
		var heads:Array<Int>;
		var tails:Array<Int>;
		var eatStack:Array<Int>;
		
		for (ike in 0...newElements.length) {

			index = newElements[ike];

			if (colorGrid[index] > 0) allUniquePlayers[colorGrid[index] - 1].size--;
			currentPlayer.size++;

			colorGrid[index] = currentPlayer.uid;
			freshGrid[index] = freshness;

			cell = GridCell.get(index);
			heads = cell.heads;
			tails = cell.tails;

			for (jen in 0...4) {
				eatStack = eatStacks[jen];
				if (lastSliceKind != jen && !inside(eatStack, heads[jen], 2)) {
					eatStack.push(heads[jen]);
					eatStack.push(tails[jen]);
				}
			}
		}

		newElements.splice(0, newElements.length);
		freshness++;
	}

	private function linearEatAlgorithm(cSlice:Array<Int>, fSlice:Array<Int>, elementList:Array<Int>):Void {
		var first:Int = -2;
		for (ike in 0...cSlice.length) {
			if (cSlice[ike] == currentPlayer.uid) {
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
			if (player.alive) player.alive = colorGrid[player.headIndex] != 0;
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
			if (colorGrid[ike] == 0 || aliveGrid[ike]) continue;
			allUniquePlayers[colorGrid[ike] - 1].size--;
			colorGrid[ike] = 0;
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

	private function endTurn():Bool {
		// give some players some powerups if this is a deluxe game
		
		turnItr++;
		if (turnItr == numAlivePlayers) {
			turnItr = 0;
			turnCount++;
			var anotherBite:Bool = turnCount % 4 == 0;
			var anotherSwap:Bool = turnCount % 6 == 0;
			for (ike in 0...players.length) {
				if (!players[ike].alive) continue;
				if (anotherBite) players[ike].bites++;
				if (anotherSwap) players[ike].swaps++;
			}
		}
		
		var lastPlayer:Player = currentPlayer;
		
		do {
			currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
			currentPlayer = players[currentPlayerIndex];
		} while (!currentPlayer.alive);
		
		makePiece();
		updateLegalBiteGrid();
		return true;
	}

	private function updateLegalBiteGrid():Void {
		legalBiteGrid.splice(0, Common.BOARD_NUM_CELLS);
		if (currentPlayer.bites > 0) {
			var w:Int = Common.BOARD_SIZE;
			for (ike in 0...Common.BOARD_NUM_CELLS) {
				if (colorGrid[ike] == currentPlayer.uid) {
					var x:Int = ike % w;
					var y:Int = Std.int((ike - x) / w);
					if ((x > 0 && colorGrid[ike - 1] != 0 && colorGrid[ike - 1] != currentPlayer.uid) ||
						(x < w - 1 && colorGrid[ike + 1] != 0 && colorGrid[ike + 1] != currentPlayer.uid) ||
						(y > 0 && colorGrid[ike - w] != 0 && colorGrid[ike - w] != currentPlayer.uid) ||
						(y < w - 1 && colorGrid[ike + w] != 0 && colorGrid[ike + w] != currentPlayer.uid)) {

						legalBiteGrid[ike] = getLegalBiteLimits(x, y);
					} else {
						legalBiteGrid[ike] = null;
					}
				}
			}
		}
	}
	
	private function getLegalBiteLimits(xCoord:Int, yCoord:Int):Array<Int> {
		
		var biteLimits:Array<Int> = [0, 0, 0, 0];
		var index:Int = yCoord * Common.BOARD_SIZE + xCoord;
		
		// find the cardinal limits of the bite
		var w:Int = Common.BOARD_SIZE;
		var lim:Int = currentPlayer.biteSize + 1;
		var topDone:Bool = false;
		var rightDone:Bool = false;
		var bottomDone:Bool = false;
		var leftDone:Bool = false;
		var newIndex:Int;

		for (ike in 1...lim) {
			
			if (!leftDone) {
				newIndex = index - ike;
				if (xCoord - ike >= 0 && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.uid) {
					biteLimits[0]--;
				} else {
					leftDone = true;
				}
			}
			
			if (!topDone) {
				newIndex = index - ike * w;
				if (yCoord - ike >= 0 && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.uid) {
					biteLimits[1]--;
				} else {
					topDone = true;
				}
			}
			
			if (!rightDone) {
				newIndex = index + ike;
				if (xCoord + ike <  w && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.uid) {
					biteLimits[2]++;
				} else {
					rightDone = true;
				}
			}
			
			if (!bottomDone) {
				newIndex = index + ike * w;
				if (yCoord + ike <  w && colorGrid[newIndex] != 0 && colorGrid[newIndex] != currentPlayer.uid) {
					biteLimits[3]++;
				} else {
					bottomDone = true;
				}
			}
			
		}
		
		return biteLimits;
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