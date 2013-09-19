package model;

typedef GridCell = {
	x:Int,
	y:Int,
	index:Int,
	heads:Array<Int>,
	tails:Array<Int>
}

class GridCellMap {

	private var cells:Array<GridCell>;
	private var boardSize:Int;

	public function get(index:Int):GridCell {
		var returnVal:GridCell = cells[index];
		if (returnVal == null) {
			var x:Int = index % boardSize;
			var y:Int = Std.int(index / boardSize);

			// H, V, U, D

			var heads:Array<Int> = [];
			var tails:Array<Int> = [];

			heads.push(y * boardSize);
			tails.push((y + 1) * boardSize);
			heads.push(x);
			tails.push(x + boardSize * boardSize);
			heads.push(Std.int(index - (Math.min(            x,                 y)) * (boardSize + 1)));
			tails.push(Std.int(index + (Math.min(boardSize - x,     boardSize - y)) * (boardSize + 1)));
			heads.push(Std.int(index - (Math.min(boardSize - x - 1,             y)) * (boardSize - 1)));
			tails.push(Std.int(index + (Math.min(            x + 1, boardSize - y)) * (boardSize - 1)));

			returnVal = cells[index] = {x:x, y:y, index:index, heads:heads, tails:tails};
		}
		return returnVal;
	}

	public function new(_boardSize:Int):Void {
		boardSize = _boardSize;
		cells = [];
	}
}
