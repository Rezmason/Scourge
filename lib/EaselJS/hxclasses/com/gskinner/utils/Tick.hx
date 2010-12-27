package com.gskinner.utils;

extern class Tick {
	static function addListener(o:Dynamic, ?pauseable:Bool):Void;
	static function removeListener(o:Dynamic):Void;
	static function removeAllListeners():Void;
	static function setInterval(interval:Int):Void;
	static function getInterval():Int;
	static function getFPS():Float;
	static function setPaused(value:Bool):Void;
	static function getPaused():Bool;
	static function getTime(?pauseable:Bool):Int;
	static function getTicks(?pauseable:Bool):Int;
}