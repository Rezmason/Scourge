package net.rezmason.scourge;

import net.rezmason.Hat;

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
	public var hat:Hat;
	
	public function new(_id:Int):Void {
		
		hat = new Hat(5);
		
		id = _id;
		name = "Player " + id;
	}
}