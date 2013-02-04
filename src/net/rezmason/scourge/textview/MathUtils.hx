package net.rezmason.scourge.textview;

class MathUtils {
    public inline static function clamp(val:Float, min:Float, max:Float):Float {
        return if (val < min) min else if (val > max) max else val;
    }
}
