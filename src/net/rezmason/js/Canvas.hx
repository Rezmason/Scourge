package net.rezmason.js;

import js.Dom;

class Canvas {
	
	public var tag(getTag, null):HtmlDom;
	public var width(getWidth, null):Float;
	public var height(getHeight, null):Float;
	
	private var _tag:HtmlDom;
	private var _width:Float;
	private var _height:Float;
	private var div:HtmlDom;
	
	public function new(_div:HtmlDom, minWidth:Float, minHeight:Float):Void {
		div = _div;
		div.innerHTML = "<canvas id=\"scourge:canvas\"></canvas>";
		_tag = div.firstChild;
	}
	
	private function getTag():HtmlDom { return _tag; }
	private function getWidth():Float { return _width; }
	private function getHeight():Float { return _height; }
	
	public function resize():Bool {
		if (_width == div.offsetWidth && _height == div.offsetHeight) return false;
		
		_width = div.offsetWidth;
		_height = div.offsetHeight;
		
		Reflect.setField(tag, "width", _width);
		Reflect.setField(tag, "height", _height);
		
		return true;
	}
}