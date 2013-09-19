package;

class Player {
	public var swaps:Int;
	public var bites:Int;
	public var size:Int;
	public var biteSize:Int;
	public var headIndex:Int;
	public var headX:Int;
	public var headY:Int;
	public var uid:Int;
	public var alive:Bool;
	public var name:String;
	public var color:Int;
	public var order:Int;

	public function new(_uid:Int):Void {

		uid = _uid;
	}

	public static function copy(player:Player):Player {
		var clone:Player = new Player(player.uid);
		clone.swaps = player.swaps;
		clone.bites = player.bites;
		clone.size = player.size;
		clone.biteSize = player.biteSize;
		clone.headIndex = player.headIndex;
		clone.headX = player.headX;
		clone.headY = player.headY;
		clone.alive = player.alive;
		clone.name = player.name;
		clone.color = player.color;
		clone.order = player.order;
		return clone;
	}

	public static function orderSort(p1:Player, p2:Player):Int {
		return p1.order - p2.order;
	}
}
