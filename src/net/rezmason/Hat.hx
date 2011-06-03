package net.rezmason;

class Hat {
	
	private var contents:Array<Int>;
	private var _mappedContents:Array<Dynamic>;
	private var _size:Int;
	private var _lastVal:Dynamic;
	
	public function new(size:Int, ?mappedContents:Array<Dynamic>):Void {
		contents = [];
		_size = size;
		if (_size < 1) _size = 1;
		if (mappedContents != null) _mappedContents = mappedContents.slice(0, _size);
		fill(this);
	}
	
	public static function pick(hat:Hat):Int {
		if (hat.contents.length == 0) fill(hat);
		return hat.contents.splice(Std.int(Math.random() * hat.contents.length), 1)[0];
	}
	
	public static function pickMapped(hat:Hat, ?returnValue:Bool = true, ?preventVal:Dynamic = null):Dynamic {
		if (hat.contents.length == 0) fill(hat);
		var candidates:Array<Int> = [];
		for (ike in 0...hat.contents.length) if (hat._mappedContents[hat.contents[ike]] != preventVal) candidates.push(ike);
		if (candidates.length == 0) return Void;
		var winner:Int = hat.contents.splice(candidates[Std.int(Math.random() * candidates.length)], 1)[0];
		hat._lastVal = hat._mappedContents[winner];
		return returnValue ? hat._lastVal : winner;
	}
	
	public static function fill(hat:Hat):Void {
		hat.contents.splice(0, hat.contents.length);
		for (ike in 0...hat._size) hat.contents.push(ike);
	}
	
	public static function copy(hat:Hat):Hat {
		var clone:Hat = new Hat(hat._size);
		clone._mappedContents = hat._mappedContents;
		clone.contents = hat.contents.copy();
		clone._lastVal = hat._lastVal;
		return clone;
	}
	
	public function outcomes(hat:Hat, ?preventVal:Dynamic = null):Array<Hat> {
		var clones:Array<Hat> = [];
		for (chance in hat.contents) {
			if (hat._mappedContents[chance] != preventVal) {
				var clone:Hat = copy(hat);
				var outcome:Int = clone.contents.splice(Std.int(Math.random() * clone.contents.length), 1)[0];
				if (clone._mappedContents != null) clone._lastVal = clone._mappedContents[outcome];
				clones.push(clone);
			}
		}
		return clones;
	}
}