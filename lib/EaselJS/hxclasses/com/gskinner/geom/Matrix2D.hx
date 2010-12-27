package com.gskinner.geom;

extern class Matrix2D {
	function new(?a:Float, ?b:Float, ?c:Float, ?d:Float, ?tx:Float, ?ty:Float):Void;
	function concat(?a:Float, ?b:Float, ?c:Float, ?d:Float, ?tx:Float, ?ty:Float):Void;
	function concatMatrix(mat:Matrix2D):Void;
	function concatTransform(?x:Float, ?y:Float, ?scaleX:Float, ?scaleY:Float, ?rotation:Float, ?regX:Float, ?regY:Float):Void;
	function rotate(angle:Float):Void;
	function scale(x:Float, y:Float):Void;
	function translate(x:Float, y:Float):Void;
	function identity():Void;
	function invert():Void;
	function clone():Dynamic;
	function toString():String;
	static var identity:Matrix2D;
	var a:Float;
	var b:Float;
	var c:Float;
	var d:Float;
	var tx:Float;
	var ty:Float;
}