package net.kawa.tween.easing;

/**
 * Expo
 * Easing equations (2**(10*t)) for the KTween class
 * @author Yusuke Kawasaki
 * @version 1.0.2
 */
class Expo {
	/**
	 * Easing equation function for expo tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeIn(t:Float):Float {
		return Math.pow(2, 10 * (t - 1));
	}

	/**
	 * Easing equation function for expo tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeOut(t:Float):Float {
		return 1.0 - Math.pow(2, -10 * t);
	}

	/**
	 * Easing equation function for expo tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeInOut(t:Float):Float {
		return (t < 0.5) ? easeIn(t * 2.0) * 0.5 : 1 - easeIn(2.0 - t * 2.0) * 0.5;
	}
}
