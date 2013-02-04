package net.rezmason.scourge.textview;

import nme.geom.ColorTransform;

class ColorUtils {
    public inline static function tint(color:Null<Int>, inverseVid:Float = 0):ColorTransform {
        var ct:ColorTransform = new ColorTransform();

        if (color == null) color = 0xFFFFFF;

        ct.redMultiplier   = (color >> 16 & 0xFF) / 0xFF;
        ct.greenMultiplier = (color >>  8 & 0xFF) / 0xFF;
        ct.blueMultiplier  = (color >>  0 & 0xFF) / 0xFF;

        inverseVid = MathUtils.clamp(inverseVid, 0, 1);
        ct.alphaOffset = Std.int(0xFF * inverseVid);
        ct.alphaMultiplier = if (inverseVid > 0.5) 1 - 2 * inverseVid else 1;

        return ct;
    }
}
