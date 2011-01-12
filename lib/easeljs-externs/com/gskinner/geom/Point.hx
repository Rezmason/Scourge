package com.gskinner.geom;

extern class Point {
	new(?x:Float, ?y:Float):Void;
	var x:Float;
	var y:Float;
	function clone():Point;
	function toString():String;
}