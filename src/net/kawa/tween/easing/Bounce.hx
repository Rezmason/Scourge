package net.kawa.tween.easing;

/**
 * Bounce
 * Easing equations (bound) for the KTween class
 * @author Yusuke Kawasaki
 * @version 1.0
 */
class Bounce {
	inline static var DH:Float = 1 / 22;
	inline static var D1:Float = 1 / 11;
	inline static var D2:Float = 2 / 11;
	inline static var D3:Float = 3 / 11;
	inline static var D4:Float = 4 / 11;
	inline static var D5:Float = 5 / 11;
	inline static var D7:Float = 7 / 11;
	inline static var IH:Float = 1 / DH;
	inline static var I1:Float = 1 / D1;
	inline static var I2:Float = 1 / D2;
	inline static var I4D:Float = 1 / D4 / D4;

	/**
	 * Easing equation function for bound tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeIn(t:Float):Float {
		var s:Float;
		if (t < D1) {
			s = t - DH;
			s = DH - s * s * IH;
		} else if (t < D3) {
			s = t - D2;
			s = D1 - s * s * I1;
		} else if (t < D7) {
			s = t - D5;
			s = D2 - s * s * I2;
		} else {
			s = t - 1;
			s = 1 - s * s * I4D;
		}
		return s;
	}

	/**
	 * Easing equation function for bound tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeOut(t:Float):Float {
		return 1.0 - easeIn(1.0 - t);
	}

	/**
	 * Easing equation function for bound tween
	 * @param t		Current time (0.0: begin, 1.0:end)
	 * @return      Current ratio (0.0: begin, 1.0:end)
	 */
	inline static public function easeInOut(t:Float):Float {
		return (t < 0.5) ? easeIn(t * 2.0) * 0.5 : 1 - easeIn(2.0 - t * 2.0) * 0.5;
	}
}
