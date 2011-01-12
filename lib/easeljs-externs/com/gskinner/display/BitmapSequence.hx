package com.gskinner.display;

extern class BitmapSequence extends DisplayObject {
	function new(spriteSheet:SpriteSheet):Void;
	
	var callback:Dynamic;
	var currentFrame:Int;
	
	var currentSequence(default,null):Dynamic;
	var currentEndFrame(default,null):Int;
	var currentStartFrame(default,null):Int;
	var nextSequence(default,null):Dynamic;
	
	var paused:Bool;
	var spriteSheet:SpriteSheet;
	
	function tick():Void;
	function cache():Void;
	function uncache():Void;
	function gotoAndPlay(frameOrSequence:Dynamic):Void;
	function gotoAndStop(frameOrSequence:Dynamic):Void;
}