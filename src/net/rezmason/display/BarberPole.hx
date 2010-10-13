package net.rezmason.display;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.events.Event;
import flash.geom.ColorTransform;
import flash.geom.Matrix;

class BarberPole extends Shape {
	
	private var stripe:BitmapData;
	private var mat:Matrix;
	private var _width:Float;
	private var _height:Float;
	private var _active:Bool;
	private var _speed:Float;
	
	public function new(?__width:Float, ?__height:Float, ?__color:Int = -1, ?__speed:Float = 15) {
		super();
		
		stripe = new BitmapData(2, 1, true, 0x0);
		stripe.setPixel32(0, 0, 0xFF000000);
		mat = new Matrix(15, 0, 10, 10);
		
		_active = false;
		_speed = __speed;
		_width = __width == null ? 200 : __width;
		_height = __height == null ? 25 : __height;
		update();
		
		if (__color > 0) {
			var ct:ColorTransform = new ColorTransform();
			ct.color = __color;
			transform.colorTransform = ct;
		}
	}
	
	public function isActive():Bool {
		return _active;
	}
	
	public function setActive(value:Bool):Void {
		if (_active == value) return;
		_active = value;
		if (_active) {
			addEventListener(Event.ENTER_FRAME, update);
		} else {
			removeEventListener(Event.ENTER_FRAME, update);
		}
	}
	
	public function update(?event:Event):Void {
		if (event != null) mat.tx += _speed;
		
		graphics.clear();
		graphics.beginBitmapFill(stripe, mat, true);
		graphics.drawRect(0, 0, _width, _height);
		graphics.endFill();
	}
}