package net.rezmason.scourge;

class Player {
	public var swaps:Int;
	public var bites:Int;
	public var size:Int;
	public var biteSize:Int;
	public var headIndex:Int;
	public var headX:Int;
	public var headY:Int;
	public var id:Int;
	public var alive:Bool;
	public var name:String;
	
	public function new(_id:Int):Void {
		id = _id;
		name = "Player " + id;
	}
}