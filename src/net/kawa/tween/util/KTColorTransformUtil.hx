package net.kawa.tween.util;

using Math;

#if js private typedef UInt = Int; #end

typedef CTObject = {
	var redMultiplier:Float;
	var greenMultiplier:Float;
	var blueMultiplier:Float;
	var redOffset:Float; 
	var greenOffset:Float;
	var blueOffset:Float;
	var alphaMultiplier:Float; 
	var alphaOffset:Float;
}

/**
 * Util class for using ColorTransform with KTween.
 * @author Yusuke Kawasaki
 * @version 1.0
 */
class KTColorTransformUtil {
	/**
	 * Generates an object to set color for ColorTransform class.
	 * @param color	Color. 0x000000: black, 0xFFFFFF: white.
	 * @param level Level of transition. 0.0: no change, 1.0: replacement.
	 * @return		An object for KTween.
	 */
	public static function color(color:UInt, level:Float = 1.0):CTObject {
		var r:Float = (level * (0xFF & (color >> 16))).floor();
		var g:Float = (level * (0xFF & (color >> 8))).floor();
		var b:Float = (level * (0xFF & color)).floor();
		var m:Float = 1.0 - level;
		return {redMultiplier: m, greenMultiplier: m, blueMultiplier: m, redOffset: r, greenOffset: g, blueOffset: b, alphaMultiplier: 1.0, alphaOffset: 0.0};
	}

	/**
	 * Generates an object to set lightness for ColorTransform class.
	 * @param level Level of lightness. 0.0: no change, 1.0: white.
	 * @return		An object for KTween.
	 */
	public static function lightness(level:Float):CTObject {
		var w:Float = level * 0xFF;
		var m:Float = 1 - level;
		return {redMultiplier: m, greenMultiplier: m, blueMultiplier: m, redOffset: w, greenOffset: w, blueOffset: w, alphaMultiplier: 1.0, alphaOffset: 0.0};
	}

	/**
	 * Generates an object to set darkness for ColorTransform class.
	 * @param level Level of darkness. 0.0: no change, 1.0: black.
	 * @return		An object for KTween.
	 */
	public static function darkness(level:Float):CTObject {
		var m:Float = 1 - level;
		return {redMultiplier: m, greenMultiplier: m, blueMultiplier: m, redOffset: 0.0, greenOffset: 0.0, blueOffset: 0.0, alphaMultiplier: 1.0, alphaOffset: 0.0};
	}
}