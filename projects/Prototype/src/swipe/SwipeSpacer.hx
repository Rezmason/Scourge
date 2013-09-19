package swipe;

import flash.display.Shape;
import flash.geom.Rectangle;

using utils.display.FastDraw;

class SwipeSpacer extends SwipeBox {

	private var background:Shape;
	private var _width:Float;
	private var _height:Float;

	public function new(?__unitHeight:Int = 1):Void {
		super(__unitHeight);
		background = new Shape();
		addChild(background);
		_width = 0;
		_height = 0;
	}

	override public function resize(width:Float, height:Float):Void {
		_width = width;
		_height = height;
		background.clear().drawBox(0x0, 0., 0, 0, _width, _height);
	}

	override private function get_box():Rectangle {
		return new Rectangle(x, y, _width, _height);
	}

	override private function set_box(value:Rectangle):Rectangle {
		x = value.x;
		y = value.y;
		resize(value.width, value.height);
		return value;
	}
}
