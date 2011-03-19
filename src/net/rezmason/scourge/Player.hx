package net.rezmason.scourge;

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
	
	public function new(_uid:Int):Void {
		
		uid = _uid;
		name = "Player " + uid;
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
		return clone;
	}
}