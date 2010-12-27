package com.gskinner.display;

extern class Bitmap extends DisplayObject {
	var image:Dynamic;
	function new(image:Dynamic):Void;
	override function draw(ctx:Dynamic, ?ignoreCache:Bool):Bool;
	function cache():Void;
	function uncache():Void;
}