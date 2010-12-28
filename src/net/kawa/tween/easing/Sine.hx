package net.kawa.tween.easing

/**
 * Sine
 * Easing equations (sin) for the KTween class
 * @author Yusuke Kawasaki
 * @version 1.0
 */
class Sine {
	static private const _HALF_PI:Float = Math.PI / 2;

	/**
	 * Easing equation function for sine tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end) 
	 */
	static public function easeIn(t:Float):Float {
		return 1.0 - Math.cos(t * _HALF_PI);
	}

	/**
	 * Easing equation function for sine tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end) 
	 */
	static public function easeOut(t:Float):Float {
		return 1.0 - easeIn(1.0 - t);
	}

	/**
	 * Easing equation function for sine tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end) 
	 */
	static public function easeInOut(t:Float):Float {
		return (t < 0.5) ? easeIn(t * 2.0) * 0.5 : 1 - easeIn(2.0 - t * 2.0) * 0.5;
	}
}
