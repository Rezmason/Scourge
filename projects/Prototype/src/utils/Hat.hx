package utils;

class Hat<T> {

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

	public static function pick<T>(hat:Hat<T>):Int {
		if (hat.contents.length == 0) fill(hat);
		return hat.contents.splice(Std.int(Math.random() * hat.contents.length), 1)[0];
	}

	public static function pickMapped<T>(hat:Hat<T>, ?preventVal:Dynamic = null):Dynamic {
		pickMappedIndex(hat, preventVal);
		return hat._lastVal;
	}

	public static function pickMappedIndex<T>(hat:Hat<T>, ?preventVal:Dynamic = null):Int {
		if (hat.contents.length == 0) fill(hat);
		var candidates:Array<Int> = [];
		for (ike in 0...hat.contents.length) if (hat._mappedContents[hat.contents[ike]] != preventVal) candidates.push(ike);
		if (candidates.length == 0) return -1;
		var winner:Int = hat.contents.splice(candidates[Std.int(Math.random() * candidates.length)], 1)[0];
		hat._lastVal = hat._mappedContents[winner];
		return winner;
	}

	public static function fill<T>(hat:Hat<T>):Void {
		hat.contents.splice(0, hat.contents.length);
		for (ike in 0...hat._size) hat.contents.push(ike);
	}

	public static function copy<T>(hat:Hat<T>):Hat<T> {
		var clone:Hat<T> = new Hat<T>(hat._size);
		clone._mappedContents = hat._mappedContents;
		clone.contents = hat.contents.copy();
		clone._lastVal = hat._lastVal;
		return clone;
	}

	public function outcomes(hat:Hat<T>, ?preventVal:Dynamic = null):Array<Hat<T>> {
		var clones:Array<Hat<T>> = [];
		for (chance in hat.contents) {
			if (hat._mappedContents[chance] != preventVal) {
				var clone:Hat<T> = copy(hat);
				var outcome:Int = clone.contents.splice(Std.int(Math.random() * clone.contents.length), 1)[0];
				if (clone._mappedContents != null) clone._lastVal = clone._mappedContents[outcome];
				clones.push(clone);
			}
		}
		return clones;
	}
}
