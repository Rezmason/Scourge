package com.gskinner.utils;

extern class Tick {
	static function addListener(o:Dynamic, ?pauseable:Bool):Void;
	static function getFPS():Float;
	static function getInterval():Int;
	static function getPaused():Bool;
	static function getTicks(pauseable:Bool):Int;
	static function getTime(?pauseable:Bool):Int;
	static function removeAllListeners():Void;
	static function removeListener(o:Dynamic):Void;
	static function setInterval(?interval:Int):Void;
	static function setPaused(value:Bool):Void;
}