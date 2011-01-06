package com.gskinner.geom;

import com.gskinner.display.DisplayObject;

extern class CoordTransform {
	static function localToGlobal(x:Float, y:Float, source:DisplayObject) : Point;
	static function globalToLocal(x:Float, y:Float, source:DisplayObject) : Point;
	static function localToLocal(x:Float, y:Float, source:DisplayObject, target:DisplayObject) : Point;
	static function getConcatenatedMatrix(target:DisplayObject, ?goal:DisplayObject) : Matrix2D;
}