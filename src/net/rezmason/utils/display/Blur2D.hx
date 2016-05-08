package net.rezmason.utils.display;

import lime.graphics.Image;
import net.rezmason.math.SoftwareBlur;

class Blur2D {

    public static function apply(source:Image, blurX, blurY) {
        var phase1 = source.clone();
        SoftwareBlur.apply(0, blurY, source.rect, retrievePixel(source), assignPixel(phase1));
        var phase2 = source.clone();
        SoftwareBlur.apply(blurX, 0, source.rect, retrievePixel(phase1), assignPixel(phase2));
        source.copyPixels(phase2, source.rect, source.rect.topLeft);
    }

    static function retrievePixel(source:Image) {
        return function(x:Float, y:Float):Array<Float> {
            var val = source.getPixel(Std.int(x), Std.int(y));
            return [for (ike in 0...4) (val >> (8 * ike)) & 0xFF];
        }
    }

    static function assignPixel(dest:Image) {
        return function(x:Float, y:Float, values:Array<Float>):Void {
            var val = 0;
            for (ike in 0...4) val = val | (Std.int(values[ike]) << (8 * ike));
            dest.setPixel(Std.int(x), Std.int(y), val);
        }
    }
}
