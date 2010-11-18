package net.rezmason.scourge.flash.display;

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
	
	//---------------------------------------
	// CONSTRUCTOR
	//---------------------------------------
	
	// Draws a grid of a certain square size. For now its colors are hard coded in.
	
	public function new(squareSize:Int, ?__width:Float = 0, ?__height:Float = 0, ?color1:UInt = 0xFFFFFFFF, ?color2:UInt = 0xFF000000) {
		super();
		gridData = new BitmapData(squareSize, squareSize, true, color1);
		smallRect = new Rectangle(0, 0, gridData.width / 2, gridData.height / 2);
		gridData.fillRect(smallRect, color2);
		smallRect.x = smallRect.y = smallRect.width;
		gridData.fillRect(smallRect, color2);
		
		setWidth(__width);
		setHeight(__height);
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
	
	//---------------------------------------
	// PRIVATE METHODS
	//---------------------------------------
	
	private function redraw():Void {
		graphics.clear();
		if (_width + _height == _width + _height) { // There must be a better isNaN for haXe
			graphics.beginBitmapFill(gridData, null, true, true);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
		}
	}
}