package com.gskinner.display;

extern class Bitmap extends DisplayObject {
	var image:Dynamic;
	function new(image:Dynamic):Void;
	function cache():Void;
	function uncache():Void;
}