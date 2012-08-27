package net.kawa.tween.easing;

/**
 * Circ
 * Easing equations (sqrt) for the KTween class
 * @author Yusuke Kawasaki
 * @version 1.0
 */
class Circ {
	/**
	 * Easing equation function for circ tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	static public function easeIn(t:Float):Float {
		return 1.0 - Math.sqrt(1.0 - t * t);
	}

	/**
	 * Easing equation function for circ tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	static public function easeOut(t:Float):Float {
		return 1.0 - easeIn(1.0 - t);
	}

	/**
	 * Easing equation function for circ tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	static public function easeInOut(t:Float):Float {
		return (t < 0.5) ? easeIn(t * 2.0) * 0.5 : 1 - easeIn(2.0 - t * 2.0) * 0.5;
	}
};
