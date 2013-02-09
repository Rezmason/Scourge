package net.rezmason.scourge.textview;

import nme.geom.ColorTransform;

class ColorUtils {
    public inline static function tint(ct:ColorTransform, color:Null<Int>, inverseVid:Float = 0):ColorTransform {

        if (color == null) color = 0xFFFFFF;

        var redMultiplier:Float   = (color >> 16 & 0xFF) / 0xFF;
        var greenMultiplier:Float = (color >>  8 & 0xFF) / 0xFF;
        var blueMultiplier:Float  = (color >>  0 & 0xFF) / 0xFF;

        inverseVid = MathUtils.clamp(inverseVid, 0, 1);
        var offset:Int = Std.int(0xFF * inverseVid);
        var multiplier:Float = if (inverseVid > 0.5) 1 - 2 * inverseVid else 1;

        ct.redOffset = offset * redMultiplier;
        ct.greenOffset = offset * greenMultiplier;
        ct.blueOffset = offset * blueMultiplier;

        ct.redMultiplier = redMultiplier * multiplier;
        ct.greenMultiplier = greenMultiplier * multiplier;
        ct.blueMultiplier = blueMultiplier * multiplier;

        return ct;
    }

    public inline static function darken(ct:ColorTransform, mult:Float = 1):ColorTransform {

        ct.redMultiplier *= mult;
        ct.greenMultiplier *= mult;
        ct.blueMultiplier *= mult;

        ct.redOffset *= mult;
        ct.greenOffset *= mult;
        ct.blueOffset *= mult;

        return ct;
    }
}
