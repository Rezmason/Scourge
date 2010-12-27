package com.gskinner.geom;

import com.gskinner.display.DisplayObject;

extern class CoordTransform {
	static function localToGlobal(x:Float, y:Float, source:DisplayObject) : Dynamic;
	static function globalToLocal(x:Float, y:Float, source:DisplayObject) : Dynamic;
	static function localToLocal(x:Float, y:Float, source:DisplayObject, target:DisplayObject) : Dynamic;
	static function getConcatenatedMatrix(target:DisplayObject, goal:DisplayObject) : Matrix2D;
}