package utils.display;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Rectangle;

class Grid extends Sprite {

	//---------------------------------------
	// PRIVATE VARIABLES
	//---------------------------------------
	private var smallRect:Rectangle;
	private var gridData:BitmapData;
	private var _width:Float;
	private var _height:Float;
	private var _cornerRadius:Float;

	//---------------------------------------
	// CONSTRUCTOR
	//---------------------------------------

	// Draws a grid of a certain square size.

	public function new(squareSize:Int, ?__width:Float = 0, ?__height:Float = 0, ?__cornerRadius:Float = 0, ?color1:UInt = 0xFFFFFFFF, ?color2:UInt = 0xFF000000) {
		super();
		gridData = new BitmapData(squareSize, squareSize, true, color1);
		smallRect = new Rectangle(0, 0, gridData.width / 2, gridData.height / 2);
		gridData.fillRect(smallRect, color2);
		smallRect.x = smallRect.y = smallRect.width;
		gridData.fillRect(smallRect, color2);

		_width = 0;
		_height = 0;
		_cornerRadius = 0;

		setWidth(__width);
		setHeight(__height);
		setCornerRadius(__cornerRadius);
	}

	//---------------------------------------
	// GETTER / SETTERS
	//---------------------------------------

	public function getWidth():Float {
		return _width;
	}

	public function setWidth(value:Float):Void {
		if (value > 0) {
			_width = value;
			redraw();
		}
	}

	public function getHeight():Float {
		return _height;
	}

	public function setHeight(value:Float):Void {
		if (value > 0) {
			_height = value;
			redraw();
		}
	}

	public function getCornerRadius():Float {
		return _cornerRadius;
	}

	public function setCornerRadius(value:Float):Void {
		if (value >= 0) {
			_cornerRadius = value;
			redraw();
		}
	}

	//---------------------------------------
	// PRIVATE METHODS
	//---------------------------------------

	private function redraw():Void {
		graphics.clear();
		if (_width + _height + _cornerRadius == _width + _height + _cornerRadius) { // There must be a better isNaN for haXe
			graphics.beginBitmapFill(gridData, null, true, true);
			graphics.drawRoundRect(0, 0, _width, _height, _cornerRadius, _cornerRadius);
			graphics.endFill();
		}
	}
}
