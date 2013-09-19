package net.kawa.tween.easing;

/**
 * Linear
 * Easing equations (t) for the KTween class
 * @author Yusuke Kawasaki
 * @version 1.0
 */
class Linear {
	/**
	 * Easing equation function for linear tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeIn(t:Float):Float {
		return t;
	}

	/**
	 * Easing equation function for linear tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeOut(t:Float):Float {
		return t;
	}

	/**
	 * Easing equation function for linear tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeInOut(t:Float):Float {
		return t;
	}
}
