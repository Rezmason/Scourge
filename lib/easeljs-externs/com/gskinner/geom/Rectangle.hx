package com.gskinner.geom;

extern class Rectangle {
	new(?x:Float, ?y:Float, ?w:Float, ?h:Float):Void;
	var h:Float;
	var w:Float;
	var x:Float;
	var y:Float;
	function clone():Rectangle;
	function toString():String;
}