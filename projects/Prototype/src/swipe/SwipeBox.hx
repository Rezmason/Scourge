package swipe;

import flash.display.Sprite;
import flash.geom.Rectangle;

class SwipeBox extends Sprite {

	public var box(get, set):Rectangle;
	public var unitHeight(default, null):Int;

	public function new(?__unitHeight:Int = 1):Void {
		super();
		unitHeight = __unitHeight;
	}

	public function resize(width:Float, height:Float):Void {

	}

	private function get_box():Rectangle {
		return new Rectangle();
	}

	private function set_box(val:Rectangle):Rectangle {
		return val;
	}
}
