package com.gskinner.display;

extern class Shape extends DisplayObject {
	var instructions:String;
	function new(instructions:String):Void;
	
	override function draw(ctx:Dynamic, ?ignoreCache:Bool):Bool;
	function clear():Void;
	
	function beginPath():Void;
	function closePath():Void;
	function moveTo(x:Float, y:Float):Void;
	function lineTo(x:Float, y:Float):Void;
	function quadraticCurveTo(cpx:Float, cpy:Float, x:Float, y:Float):Void;
	function bezierCurveTo(cpx1:Float, cpy1:Float, cpx2:Float, cpy2:Float, x:Float, y:Float):Void;
	function arcTo(x1:Float, y1:Float, x2:Float, y2:Float, radius:Float):Void;
	function rect(x:Float, y:Float, w:Float, h:Float):Void;
	function arc(x:Float, y:Float, radius:Float, startAngle:Float, endAngle:Float, anticlockwise:Bool):Void;
	function fill():Void;
	function stroke():Void;
	function clip():Void;
	function fillRect(x:Float, y:Float, w:Float, h:Float):Void;
	function strokeRect(x:Float, y:Float, w:Float, h:Float):Void;
	function setFillStyle(value:String):Void;
	function setStrokeStyle(value:String):Void;
	function setLineWidth(value:String):Void;
	function setLineCap(value:String):Void;
	override function clone():Dynamic;
	override function toString():String;
	
}