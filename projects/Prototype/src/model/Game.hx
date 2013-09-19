package model;

import model.GridCellMap;

import Common;

import Pieces;

using Reflect;
using Type;

typedef PieceHat = utils.Hat<PieceDef>;

class Game {

	private var defaultGrid:Array<Dynamic>;

	private var _state:GameState;
	private var history:Array<GameState>;
	private var histIndex:Int;
	private var pHat:PieceHat;
	private var allPlayerActions:Array<Dynamic>;

	// specific to the eat algorithm
	private var eatStacks:Array<Array<Int>>;
	private var hStack:Array<Int>;
	private var vStack:Array<Int>;
	private var uStack:Array<Int>;
	private var dStack:Array<Int>;
	private var newElements:Array<Int>;

	public function new(?_defaultGrid:Array<Dynamic>):Void {

		defaultGrid = (_defaultGrid[0] == -1) ? null : _defaultGrid;
		// Set up data structure
		newElements = [];
		hStack = [];
		vStack = [];
		uStack = [];
		dStack = [];
		history = [];
		eatStacks = [hStack, vStack, uStack, dStack]; // H, V, U, D
		fillTable(Pieces.PIECES);
		fillTable(Pieces.CENTERS);
		fillTable(Pieces.NEIGHBORS);
		allPlayerActions = [forfeit, endTurn, swapPiece, takeBite, placePiece];
		pHat = new PieceHat(Pieces.PIECES.length, Pieces.PIECES);
	}


	public function begin(?_numPlayers:Int = 1, ?gameType:GameType, ?circular:Bool):Void {

		history.splice(0, history.length);
		histIndex = 0;

		_state = new GameState();

		_state.numPlayers = (_numPlayers < 0) ? 1 : ((_numPlayers > Common.MAX_PLAYERS) ? Common.MAX_PLAYERS : _numPlayers);
		_state.numAlivePlayers = _state.numPlayers;

		if (gameType == null) gameType = GameType.CLASSIC;

		switch (gameType) {
			case CLASSIC:
			case GENETIC:
		}

		var startAngle:Float = 0.75;
		var playerAngle:Float = 2 / _state.numPlayers;
		var bR:Float = (_state.numPlayers == 1) ? 0 : Common.PLAYER_DISTANCE / (2 * Math.sin(Math.PI * playerAngle * 0.5));

		var minHeadX:Float = bR * 2 + 1;
		var maxHeadX:Float = -1;
		var minHeadY:Float = bR * 2 + 1;
		var maxHeadY:Float = -1;

		_state.players.splice(0, _state.players.length);

		var players:Array<Player> = [];
		var positions:Array<{x:Float, y:Float}> = [];

		// Populate the player list. Propose the first set of coordinates
		for (ike in 0..._state.numPlayers) {
			var player:Player = new Player(ike + 1);
			players.push(player);
			player.bites = 2;
			player.swaps = 10;
			player.size = 1;
			player.biteSize = 1;
			player.alive = true;

			player.name = 'Player ${player.uid}'; // for now
			player.color = ike;
			player.order = ike + 1;

			var angle:Float = Math.PI * ((player.order - 1) * playerAngle + startAngle);
			var pos:{x:Float, y:Float} = {x:Math.cos(angle) * bR, y:Math.sin(angle) * bR};
			positions[ike] = pos;

			minHeadX = Math.min(minHeadX, pos.x);
			minHeadY = Math.min(minHeadY, pos.y);
			maxHeadX = Math.max(maxHeadX, pos.x + 1);
			maxHeadY = Math.max(maxHeadY, pos.y + 1);
		}

		var scaleX:Float = (maxHeadX - minHeadX) / (2 * bR);
		var scaleY:Float = (maxHeadY - minHeadY) / (2 * bR);

		minHeadX = bR * 2 + 1;
		maxHeadX = -1;
		minHeadY = bR * 2 + 1;
		maxHeadY = -1;

		for (ike in 0..._state.numPlayers) {
			var player:Player = players[ike];

			var angle:Float = Math.PI * ((player.order - 1) * playerAngle + startAngle);
			player.headX = Math.floor(Math.cos(angle) * bR / scaleX);
			player.headY = Math.floor(Math.sin(angle) * bR / scaleY);

			minHeadX = Math.min(minHeadX, player.headX);
			minHeadY = Math.min(minHeadY, player.headY);
			maxHeadX = Math.max(maxHeadX, player.headX + 1);
			maxHeadY = Math.max(maxHeadY, player.headY + 1);
		}

		_state.boardSize = Std.int(maxHeadX - minHeadX + 2 * Common.BOARD_PADDING);
		_state.boardNumMaskedCells = _state.boardNumCells = _state.boardSize * _state.boardSize;
		_state.changeIncrements = [1, _state.boardSize, _state.boardSize + 1, _state.boardSize - 1];
		_state.gridCellMap = new GridCellMap(_state.boardSize);

		for (ike in 0..._state.numPlayers) {
			var player:Player = players[ike];
			player.headX += Std.int(Common.BOARD_PADDING - minHeadX);
			player.headY += Std.int(Common.BOARD_PADDING - minHeadY);
			player.headIndex = player.headY * _state.boardSize + player.headX;
			_state.bodyGrid[player.headIndex] = player.order;
		}

		_state.players = players.copy();
		_state.players.sort(Player.orderSort);


		if (circular) {
			_state.maskGrid = [];
			var w:Int = _state.boardSize;
			var count:Int = 0;
			for (ike in 0..._state.boardNumCells) {
				var x:Int = ike % w;
				var y:Int = Std.int((ike - x) / w);
				var fx:Float = x - 0.5 * w + 0.5;
				var fy:Float = y - 0.5 * w + 0.5;

				if (Math.abs(Math.sqrt(fx * fx + fy * fy)) < w * 0.5) {
					_state.maskGrid[ike] = 1;
					count++;
				} else {
					_state.maskGrid[ike] = 0;
				}
			}
			_state.boardNumMaskedCells = count;
		}

		// Prime the grid
		if (defaultGrid != null) {
			for (ike in 0..._state.numPlayers) _state.players[ike].size = 0;
			for (ike in 0..._state.boardNumCells) {
				_state.bodyGrid[ike] = Std.int(defaultGrid[ike]);
				if (_state.bodyGrid[ike] > 0) _state.players[_state.bodyGrid[ike] - 1].size++;
			}
		}

		resetFreshness(_state);
		killCheck(_state);
		history.push(_state);

		// It's player 1's turn
		_state.currentPlayerIndex = 0;
		_state.turnItr = 0;
		_state.turnCount = 0;
		_state.currentPlayer = _state.players[_state.currentPlayerIndex];
		_state.currentPiece = -1;

		makePiece(_state);
		updateLegalBiteGrid(_state);
	}

	public function getBoardSize():Int { return _state.boardSize; }
	public function getBoardNumCells():Int { return _state.boardNumCells; }
	public function getPiece(?copy:Bool):Array<Array<Int>> { return copy ? Pieces.PIECES[_state.currentPiece].copy() : Pieces.PIECES[_state.currentPiece]; }
	public function getPieceCenter(?copy:Bool):Array<Array<Float>> { return copy ? Pieces.CENTERS[_state.currentPiece].copy() : Pieces.CENTERS[_state.currentPiece]; }
	public function getLegalBiteGrid(?copy:Bool):Array<Array<Int>> { return copy ? _state.legalBiteGrid.copy() : _state.legalBiteGrid; }
	public function getBodyGrid(?copy:Bool):Array<Int> { return copy ? _state.bodyGrid.copy() : _state.bodyGrid; }
	public function getFreshGrid(?copy:Bool):Array<Int> { return copy ? _state.freshGrid.copy() : _state.freshGrid; }
	public function getLifeGrid(?copy:Bool):Array<Int> { return copy ? _state.lifeGrid.copy() : _state.lifeGrid; }
	public function getMaxFreshness():Int { return _state.freshness; }
	public function getCurrentPlayer(?copy:Bool):Player { return copy ? Player.copy(_state.currentPlayer) : _state.currentPlayer; }
	public function getCurrentPlayerIndex():Int { return _state.currentPlayerIndex; }
	public function getNumPlayers():Int { return _state.numPlayers; }
	public function getPlayers(?copy:Bool):Array<Player> { return copy ? _state.players.copy() : _state.players; }
	public function testPosition(xCoord:Int, yCoord:Int, angle:Int):Bool { return _state.legalMoveGrids[angle][yCoord * _state.boardSize + xCoord]; }
	public function getBitePhase():Float { return (_state.turnCount % Common.BITE_FREQUENCY) / (Common.BITE_FREQUENCY - 1); }
	public function getSwapPhase():Float { return (_state.turnCount % Common.SWAP_FREQUENCY) / (Common.SWAP_FREQUENCY - 1); }

	public function act(action:PlayerAction):Void {
		var params:Array<Dynamic> = action.enumParameters();
		_state = GameState.copy(_state);
		histIndex++;
		history.splice(histIndex, history.length - histIndex);
		history.push(_state);
		params.unshift(_state);
		callMethod(allPlayerActions[action.enumIndex()], params);
	}

	public function undoAction():Bool {
		if (histIndex == 0) return false;
		histIndex--;
		_state = history[histIndex];
		return true;
	}

	public function redoAction():Bool {
		if (histIndex == history.length - 1) return false;
		histIndex++;
		_state = history[histIndex];
		return true;
	}

	private function fillTable(table:Array<Array<Dynamic>>):Void {
		for (row in table) {
			var originalLength:Int = row.length;
			if (originalLength < 4) {
				for (ike in originalLength...4) {
					row.push(row[ike % originalLength]);
				}
			}
		}
	}

	private function makePiece(state:GameState, ?swap:Bool = false):Void {
		if (!swap) PieceHat.fill(pHat);
		state.currentPiece = PieceHat.pickMappedIndex(pHat, Pieces.PIECES[state.currentPiece]);
		updateLegalMoveGrids(state);
	}

	private function swapPiece(state:GameState):Void {
		if (state.numPlayers != 1 && state.currentPlayer.swaps <= 0) return;
		state.currentPlayer.swaps--;
		makePiece(state, true);
	}

	private function takeBite(state:GameState, startXCoord:Int, startYCoord:Int, endXCoord:Int, endYCoord:Int):Void {
		if ((endXCoord != startXCoord) == (endYCoord != startYCoord)) return;

		var startIndex:Int = startYCoord * state.boardSize + startXCoord;
		var endIndex  :Int = endYCoord   * state.boardSize + endXCoord;

		var biteLimits:Array<Int> = state.legalBiteGrid[startIndex];
		if (biteLimits == null) return;

		var differences:Array<Int> = [endXCoord - startXCoord, endYCoord - startYCoord];
		var vertical:Int = (endXCoord == startXCoord) ? 1 : 0;
		if (differences[vertical] < biteLimits[vertical] || differences[vertical] > biteLimits[2 + vertical]) return;

		resetFreshness(state);

		// clear the bite region

		var step:Int = (startXCoord == endXCoord) ? state.boardSize : 1;
		var index:Int = endIndex;
		do {
			state.bodyGrid[index] = 0;
			state.freshGrid[index] = state.freshness;
			if (index < startIndex) {
				index += step;
			} else {
				index -= step;
			}
		} while (index != startIndex);


		killCheck(state);
		state.currentPlayer.bites--;
		updateLegalBiteGrid(state);
		updateLegalMoveGrids(state);
		return;
	}

	private function placePiece(state:GameState, x:Int, y:Int, angle:Int):Void {

		if (!testPosition(x, y, angle)) return;

		resetFreshness(state);

		var currentBlocks:Array<Int> = getPiece()[angle];
		var spotX:Int, spotY:Int;
		var index:Int;
		var ike:Int = 0;
		while (ike < currentBlocks.length) {
			index = (y + currentBlocks[ike + 1]) * state.boardSize + x + currentBlocks[ike];
			// change current player's size
			newElements.push(index);
			ike += 2;
		}

		processChangesIntoSlices(state, -1);

		var colorSlice:Array<Int> = [];
		var freshSlice:Array<Int> = [];
		var flatElements:Array<Int> = [];

		var stack:Array<Int>;
		var tail:Int, head:Int, changeIncrement:Int;

		var ike:Int, jen:Int, ken:Int;

		while (hStack.length + vStack.length + uStack.length + dStack.length > 0) {
			for (ike in 0...eatStacks.length) {
				stack = eatStacks[ike];
				changeIncrement = state.changeIncrements[ike];
				while (stack.length > 0) { // stack loop
					tail = stack.pop();
					head = stack.pop();
					jen = head;
					ken = 0;

					colorSlice.splice(0, colorSlice.length);
					freshSlice.splice(0, freshSlice.length);
					flatElements.splice(0, flatElements.length);

					while (jen != tail) {
						colorSlice[ken] = state.bodyGrid[jen];
						freshSlice[ken] = state.freshGrid[jen];
						jen += changeIncrement;
						ken++;
					}

					linearEatAlgorithm(state, colorSlice, freshSlice, flatElements);
					for (elem in flatElements) newElements.push(head + elem * changeIncrement);
					for (player in state.players) {
						if (player.alive && inside(newElements, player.headIndex)) {
							player.alive = false;
							for (ken in 0...state.boardNumCells) if (state.bodyGrid[ken] == player.order) newElements.push(ken);
						}
					}

					if (newElements.length > 0) processChangesIntoSlices(state, ike);
				}
			}
		}

		killCheck(state);
		endTurn(state);
	}

	private function forfeit(state:GameState):Void {
		if (state.numAlivePlayers == 1) return;
		state.bodyGrid[state.currentPlayer.headIndex] = 0;
		resetFreshness(state);
		killCheck(state);
		state.currentPlayer.alive = false;
		state.numAlivePlayers--;
		endTurn(state);
	}

	private function endTurn(state:GameState):Void {
		// give some players some powerups if this is a deluxe game

		state.turnItr++;
		if (state.turnItr == state.numAlivePlayers) {
			state.turnItr = 0;
			state.turnCount++;
			var anotherBite:Bool = state.turnCount % Common.BITE_FREQUENCY == 0;
			var anotherSwap:Bool = state.turnCount % Common.SWAP_FREQUENCY == 0;
			for (player in state.players) {
				if (!player.alive) continue;
				if (anotherBite && player.bites < Common.MAX_BITES) player.bites++;
				if (anotherSwap && player.swaps < Common.MAX_SWAPS) player.swaps++;
			}
		}

		var lastPlayer:Player = state.currentPlayer;

		do {
			state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.length;
			state.currentPlayer = state.players[state.currentPlayerIndex];
		} while (!state.currentPlayer.alive);

		makePiece(state);
		updateLegalBiteGrid(state);
	}

	private function updateLegalMoveGrids(state:GameState):Void {
		var pieceData:Array<Array<Int>> = Pieces.PIECES[state.currentPiece];
		var neighborData:Array<Array<Int>> = Pieces.NEIGHBORS[state.currentPiece];

		for (ike in 0...pieceData.length) {
			var currentBlocks:Array<Int> = pieceData[ike];
			var currentNeighbors:Array<Int> = neighborData[ike];
			if (state.legalMoveGrids[ike] == null) state.legalMoveGrids[ike] = [];
			var legalMoveGridForAngle:Array<Bool> = state.legalMoveGrids[ike];
			for (jen in 0...state.boardNumCells) legalMoveGridForAngle[jen] = testMoveLegality(state, jen, currentBlocks, currentNeighbors);
		}
	}

	private function testMoveLegality(state:GameState, index:Int, blocks:Array<Int>, neighbors:Array<Int>):Bool {
		var spotX:Int, spotY:Int;
		var w:Int = state.boardSize;
		var ike:Int;
		var yCoord:Int = Std.int(index / w);
		var xCoord:Int = index - (yCoord * w);

		// easy tests for failure
		ike = 0;
		while (ike < blocks.length) {
			spotX = xCoord + blocks[ike]; spotY = yCoord + blocks[ike + 1];
			if (spotX < 0 || spotX >= w) return false; // off the grid
			if (spotY < 0 || spotY >= w) return false; // off the grid
			if (state.maskGrid != null && state.maskGrid[spotY * w + spotX] == 0) return false; // spot masked out
			if (state.bodyGrid[spotY * w + spotX] != 0) return false; // spot taken
			ike += 2;
		}

		// neighbor test
		ike = 0;
		while (ike < neighbors.length) {
			spotX = xCoord + neighbors[ike]; spotY = yCoord + neighbors[ike + 1];
			if (state.bodyGrid[spotY * w + spotX] == state.currentPlayer.order) return true; // neighbor exists
			ike += 2;
		}

		return false;
	}

	private function updateLegalBiteGrid(state:GameState):Void {
		state.legalBiteGrid.splice(0, state.boardNumCells);
		if (state.currentPlayer.bites > 0) {
			var w:Int = state.boardSize;
			for (ike in 0...state.boardNumCells) {
				if (state.bodyGrid[ike] == state.currentPlayer.order) {
					var x:Int = ike % w;
					var y:Int = Std.int((ike - x) / w);
					if ((x > 0 && state.bodyGrid[ike - 1] != 0 && state.bodyGrid[ike - 1] != state.currentPlayer.order) ||
						(x < w - 1 && state.bodyGrid[ike + 1] != 0 && state.bodyGrid[ike + 1] != state.currentPlayer.order) ||
						(y > 0 && state.bodyGrid[ike - w] != 0 && state.bodyGrid[ike - w] != state.currentPlayer.order) ||
						(y < w - 1 && state.bodyGrid[ike + w] != 0 && state.bodyGrid[ike + w] != state.currentPlayer.order)) {

						state.legalBiteGrid[ike] = getLegalBiteLimits(state, x, y);
					} else {
						state.legalBiteGrid[ike] = null;
					}
				}
			}
		}
	}

	private function getLegalBiteLimits(state:GameState, xCoord:Int, yCoord:Int):Array<Int> {

		var biteLimits:Array<Int> = [0, 0, 0, 0];
		var index:Int = yCoord * state.boardSize + xCoord;

		// find the cardinal limits of the bite
		var w:Int = state.boardSize;
		var lim:Int = state.currentPlayer.biteSize + 1;
		var topDone:Bool = false;
		var rightDone:Bool = false;
		var bottomDone:Bool = false;
		var leftDone:Bool = false;
		var newIndex:Int;

		for (ike in 1...lim) {

			if (!leftDone) {
				newIndex = index - ike;
				if (xCoord - ike >= 0 && state.bodyGrid[newIndex] != 0 && state.bodyGrid[newIndex] != state.currentPlayer.order) {
					biteLimits[0]--;
				} else {
					leftDone = true;
				}
			}

			if (!topDone) {
				newIndex = index - ike * w;
				if (yCoord - ike >= 0 && state.bodyGrid[newIndex] != 0 && state.bodyGrid[newIndex] != state.currentPlayer.order) {
					biteLimits[1]--;
				} else {
					topDone = true;
				}
			}

			if (!rightDone) {
				newIndex = index + ike;
				if (xCoord + ike <  w && state.bodyGrid[newIndex] != 0 && state.bodyGrid[newIndex] != state.currentPlayer.order) {
					biteLimits[2]++;
				} else {
					rightDone = true;
				}
			}

			if (!bottomDone) {
				newIndex = index + ike * w;
				if (yCoord + ike <  w && state.bodyGrid[newIndex] != 0 && state.bodyGrid[newIndex] != state.currentPlayer.order) {
					biteLimits[3]++;
				} else {
					bottomDone = true;
				}
			}

		}

		return biteLimits;
	}

	private function resetFreshness(state:GameState):Void {
		state.freshness = 1;
		for (ike in 0...state.boardNumCells) state.freshGrid[ike] = 0;
	}

	private function processChangesIntoSlices(state:GameState, lastSliceKind:Int):Void {

		var index:Int;
		var cell:GridCell;
		var heads:Array<Int>;
		var tails:Array<Int>;
		var eatStack:Array<Int>;

		for (index in newElements) {

			if (state.bodyGrid[index] > 0) _state.players[state.bodyGrid[index] - 1].size--;
			state.currentPlayer.size++;

			state.bodyGrid[index] = state.currentPlayer.order;
			state.freshGrid[index] = state.freshness;

			cell = state.gridCellMap.get(index);
			heads = cell.heads;
			tails = cell.tails;

			for (ike in 0...4) {
				eatStack = eatStacks[ike];
				if (lastSliceKind != ike && !inside(eatStack, heads[ike], 2)) {
					eatStack.push(heads[ike]);
					eatStack.push(tails[ike]);
				}
			}
		}

		newElements.splice(0, newElements.length);
		state.freshness++;
	}

	private function linearEatAlgorithm(state:GameState, cSlice:Array<Int>, fSlice:Array<Int>, elementList:Array<Int>):Void {
		var first:Int = -2;
		for (ike in 0...cSlice.length) {
			if (cSlice[ike] == state.currentPlayer.order) {
				if (first != -2 && (fSlice[first] + fSlice[ike] > 0)) for (jen in first + 1...ike) elementList.push(jen);
				first = ike;
			} else if (cSlice[ike] == 0) {
				first = -2;
			}
		}
	}

	private function killCheck(state:GameState):Void {

		state.lifeGrid.splice(0, state.lifeGrid.length);
		state.lifeGrid[state.boardNumCells - 1] = 0;

		// start with the living heads
		for (player in state.players) {
			if (player.alive) player.alive = state.bodyGrid[player.headIndex] != 0;
			if (player.alive) {
				newElements.push(player.headIndex);
				state.lifeGrid[player.headIndex] = 1;
			}
		}

		var w:Int = state.boardSize;
		var ike:Int = 0;
		var num:Int = newElements.length;

		// throw neighbors into newElements
		while (ike < num) {
			var index:Int = newElements[ike];
			var yCoord:Int = Std.int(index / w);
			var xCoord:Int = index - (yCoord * w);
			var color:Int = state.bodyGrid[index];
			var life:Int = state.lifeGrid[index] + 1;
			var amt:Int;

			amt = index - 1;
			if (xCoord > 0     && !(state.lifeGrid[amt] > 0) && color == state.bodyGrid[amt]) {
				state.lifeGrid[amt] = life;
				newElements.push(amt);
				num++;
			}

			amt = index + 1;
			if (xCoord < w - 1 && !(state.lifeGrid[amt] > 0) && color == state.bodyGrid[amt]) {
				state.lifeGrid[amt] = life;
				newElements.push(amt);
				num++;
			}

			amt = index - w;
			if (yCoord > 0     && !(state.lifeGrid[amt] > 0) && color == state.bodyGrid[amt]) {
				state.lifeGrid[amt] = life;
				newElements.push(amt);
				num++;
			}

			amt = index + w;
			if (yCoord < w - 1 && !(state.lifeGrid[amt] > 0) && color == state.bodyGrid[amt]) {
				state.lifeGrid[amt] = life;
				newElements.push(amt);
				num++;
			}

			ike++;
		}

		// delete the cells that aren't flagged
		for (ike in 0...state.lifeGrid.length) {
			if (state.bodyGrid[ike] > 0 && !(state.lifeGrid[ike] > 0)) {
				_state.players[state.bodyGrid[ike] - 1].size--;
				state.bodyGrid[ike] = 0;
				state.freshGrid[ike] = state.freshness;
			}
		}

		// resize the state.players
		for (player in state.players) {
			if (player.alive) {
				if (player.size < 0.2 * state.boardNumMaskedCells) {
					player.biteSize = 1;
				} else if (player.size < 0.4 * state.boardNumMaskedCells) {
					player.biteSize = 2;
				} else {
					player.biteSize = 3;
				}
			}
		}

		newElements.splice(0, newElements.length);
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
