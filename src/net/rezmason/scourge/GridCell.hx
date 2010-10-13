package net.rezmason.scourge;

class GridCell {
	
	public var x:Int;
	public var y:Int;
	public var index:Int;
	
	public var heads:Array<Int>;
	public var tails:Array<Int>;
	
	private static var cells:Array<GridCell> = [];
	
	public static function get(_index:Int):GridCell {
		var returnVal:GridCell = cells[_index];
		if (returnVal == null) returnVal = cells[_index] = new GridCell(_index);
		return returnVal;
	}
	
	public function new(_index:Int):Void {
		var width:Int = Common.BOARD_SIZE;
		
		index = _index;
		x = index % width;
		y = Std.int(index / width);
		
		// H, V, U, D
		
		heads = [];
		tails = [];
		
		heads.push(y * width);
		tails.push((y + 1) * width);
		heads.push(x);
		tails.push(x + width * width);
		heads.push(Std.int(index - (Math.min(        x,             y)) * (width + 1)));
		tails.push(Std.int(index + (Math.min(width - x,     width - y)) * (width + 1)));
		heads.push(Std.int(index - (Math.min(width - x - 1,         y)) * (width - 1)));
		tails.push(Std.int(index + (Math.min(        x + 1, width - y)) * (width - 1)));
	}
}