package com.gskinner.display;

extern class Container extends DisplayObject {
	function new():Void;
	
	var children:Array<DisplayObject>;
	var mouseChildren:Bool;
	
	override function draw(ctx:Dynamic, ?ignoreCache:Bool):Bool;
	function addChild(child:DisplayObject):DisplayObject;
	function addChildAt(child:DisplayObject, index:Int):DisplayObject;
	function removeChild(child:DisplayObject):DisplayObject;
	function removeAllChildren():Void;
	function getChildAt(index:Int):DisplayObject;
	function sortChildren(sortFunction:Dynamic):Void;
	function removeChildAt(child:DisplayObject, index:Int):DisplayObject;
	function getChildIndex(child:DisplayObject):Int;
	function getNumChildren():Int;
	override function clone():Dynamic;
	override function toString():String;
}