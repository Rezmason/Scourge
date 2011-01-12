package com.gskinner.display;

extern class Container extends DisplayObject {
	function new():Void;
	
	var children:Array<DisplayObject>;
	var mouseChildren:Bool;
	
	function addChild(child:DisplayObject):DisplayObject;
	function addChildAt(child:DisplayObject, index:Int):DisplayObject;
	function getChildAt(index:Int):DisplayObject;
	function getChildIndex(child:DisplayObject):Int;
	function getNumChildren():Int;
	function removeAllChildren():Void;
	function removeChild(child:DisplayObject):DisplayObject;
	function removeChildAt(child:DisplayObject, index:Int):DisplayObject;
	function sortChildren(sortFunction:DisplayObject->DisplayObject->Int):Void;
	
}