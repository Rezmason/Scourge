package net.kawa.tween.easing;

/**
 * Cubic
 * Easing equations (t**3) for the KTween class
 * @author Yusuke Kawasaki
 * @version 1.0
 */
class Cubic {
	/**
	 * Easing equation function for cubic tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeIn(t:Float):Float {
		return t * t * t;
	}

	/**
	 * Easing equation function for cubic tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeOut(t:Float):Float {
		return 1.0 - easeIn(1.0 - t);
	}

	/**
	 * Easing equation function for cubic tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeInOut(t:Float):Float {
		return (t < 0.5) ? easeIn(t * 2.0) * 0.5 : 1 - easeIn(2.0 - t * 2.0) * 0.5;
	}
}
