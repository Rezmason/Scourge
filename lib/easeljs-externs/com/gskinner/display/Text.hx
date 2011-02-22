package com.gskinner.display;

extern class Text extends DisplayObject {
	
	function new(?text:String, ?font:String, ?color:String):Void;
	
	var color:Int;
	var font:String;
	var maxWidth:Float;
	var outline:Bool;
	var text:String;
	var textAlign:String;
	var textBaseline:String;

	function getMeasuredWidth():Float;	
}