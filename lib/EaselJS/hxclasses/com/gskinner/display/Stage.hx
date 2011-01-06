package com.gskinner.display;

extern class Stage extends Container {
	var autoClear:Bool;
	var canvas:Dynamic;
	function new(canvas:Dynamic):Void;
	function tick():Void;
	function clear():Void;
	function getObjectsUnderPoint(x:Float, y:Float):Array<DisplayObject>;
	function getObjectUnderPoint(x:Float, y:Float):Array<DisplayObject>;
}