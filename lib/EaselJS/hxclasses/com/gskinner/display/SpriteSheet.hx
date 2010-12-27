package com.gskinner.display;

extern class SpriteSheet {
	var image:Dynamic;
	var frameWidth:Int;
	var frameHeight:Int
	var frameData:Dynamic;
	var loop:Bool
	var totalFrames:Int;
	function new(image:Dynamic, frameWidth:Int, frameHeight:Int, frameData:Dynamic):Void;
	override function clone():Dynamic;
	override function toString():String;
}