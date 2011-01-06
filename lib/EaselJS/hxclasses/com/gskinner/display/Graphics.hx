package com.gskinner.display;

extern class Graphics extends DisplayObject {
	var instructions:String;
	
	var curveTo:Float->Float->Float->Float->Graphics;
	var drawRect:Float->Float->Float->Float->Graphics;
	
	function new(?instructions:Graphics):Void;
	
	function arc(x:Float, y:Float, radius:Float, startAngle:Float, endAngle:Float, anticlockwise:Bool):Graphics;
	function arcTo(x1:Float, y1:Float, x2:Float, y2:Float, radius:Float):Graphics;
	function beginBitmapFill(image:Dynamic, ?repetition:String):Graphics;
	function beginBitmapStroke(image:Dynamic, ?repetition:String):Graphics;
	function beginFill(color:String):Graphics;
	function beginLinearGradientFill(colors:Array<String>, ratios:Array<Float>, x0:Float, y0:Float, x1:Float, y1:Float):Graphics;
	function beginLinearGradientStroke(colors:Array<String>, ratios:Array<Float>, x0:Float, y0:Float, x1:Float, y1:Float):Graphics;
	function beginRadialGradientFill(colors:Array<String>, ratios:Array<Float>, x0:Float, y0:Float, r0:Float, x1:Float, y1:Float, r1:Float):Graphics;
	function beginRadialGradientStroke(colors:Array<String>, ratios:Array<Float>, x0:Float, y0:Float, r0:Float, x1:Float, y1:Float, r1:Float):Graphics;
	function beginStroke(color:String):Graphics;
	function bezierCurveTo(cp1x:Float, cp1y:Float, cp2x:Float, cp2y:Float, x:Float, y:Float):Graphics;
	function clear():Graphics;
	function closePath():Void;
	function drawCircle(x:Float, y:Float, radius:Float):Graphics;
	function drawEllipse(x:Float, y:Float, w:Float, h:Float):Graphics;
	function drawRoundRect(x:Float, y:Float, w:Float, h:Float, radius:Float):Graphics;
	function drawRoundRectComplex(x:Float, y:Float, w:Float, h:Float, radiusTL:Float, radiusTR:Float, radiusBR:Float, radiusBL:Float):Graphics;
	function endFill():Graphics;
	function endStroke():Graphics;
	function lineTo(x:Float, y:Float):Graphics;
	function moveTo(x:Float, y:Float):Graphics;
	function quadraticCurveTo(cpx:Float, cpy:Float, x:Float, y:Float):Graphics;
	function rect(x:Float, y:Float, w:Float, h:Float):Graphics;
	function setStrokeStyle(thickness:Float, ?caps:String, ?joints:String, ?miter:Float):Graphics;
	function fillRect(x:Float, y:Float, w:Float, h:Float):Void;
	
	static function getHSL(hue:Float, saturation:Float, lightness:Float, ?alpha:Float):String;
	static function getRGB(r:Float, g:Float, b:Float, ?alpha:Float):String;
}