package com.gskinner.display;

extern class Shadow {
	static var identity:Shadow;
	var blur:Float;
	var color:Int;
	var offsetX:Float;
	var offsetY:Float;
	function new(color:Int, offsetX:Float, offsetY:Float, blur:Float):Void;
	function toString():String;
	function clone():Dynamic;
}