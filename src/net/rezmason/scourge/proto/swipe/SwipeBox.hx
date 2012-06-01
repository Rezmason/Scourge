package net.rezmason.scourge.proto.swipe;

import flash.display.Sprite;
import flash.geom.Rectangle;

class SwipeBox extends Sprite {

	public var box(getBox, setBox):Rectangle;
	public var unitHeight(default, null):Int;

	public function new(?__unitHeight:Int = 1):Void {
		super();
		unitHeight = __unitHeight;
	}

	public function resize(width:Float, height:Float):Void {

	}

	private function getBox():Rectangle {
		return new Rectangle();
	}

	private function setBox(val:Rectangle):Rectangle {
		return val;
	}
}
