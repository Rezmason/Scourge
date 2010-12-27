package net.rezmason;

class Hat {
	
	private var contents:Array<Int>;
	private var _size:Int;
	
	public function new(size:Int):Void {
		contents = [];
		_size = size;
		fill();
	}
	
	public function pick():Int {
		if (contents.length == 0) fill();
		return contents.splice(Std.int(Math.random() * contents.length), 1)[0];
	}
	
	public function fill():Void {
		contents.splice(0, contents.length);
		for (ike in 0..._size) contents.push(ike);
	}
}