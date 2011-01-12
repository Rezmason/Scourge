package com.gskinner.display;

extern class DisplayObject {
	function new():Void;
	
	var alpha:Float;

	var cacheCanvas(default,null):DisplayObject;
	var id:Int;
	
	var mouseEnabled:Bool;
	var name:String;
	var parent:Container;
	var regX:Float;
	var regY:Float;
	var rotation:Float;
	var scaleX:Float;
	var scaleY:Float;
	var shadow:Shadow;
	var visible:Bool;
	var x:Float;
	var y:Float;
	
	function updateContext(ctx:Dynamic, ?ignoreShadows:Bool):Void;
	//function draw(ctx:Dynamic, ?ignoreCache:Bool):Bool;
	function revertContext():Void;
	function cache(x:Float, y:Float, w:Float, h:Float):Void;
	function uncache():Void;
	function getStage():Stage;
	function clone():DisplayObject;
	function toString():String;
}