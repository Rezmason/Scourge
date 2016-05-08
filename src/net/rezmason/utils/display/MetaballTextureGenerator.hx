package net.rezmason.utils.display;

import lime.graphics.Image;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoPattern;
import net.rezmason.math.SoftwareBlur;

class MetaballTextureGenerator {

    public static function makeTexture(radius:Float, ratio:Float, blurAmount:Float):Image {

        var size:Int = Std.int((radius + blurAmount) * 2);

        var image = new Image(null, 0, 0, size, size);
        image.fillRect(image.rect, 0x000000FF, BGRA32);

        var cairo = new Cairo(CairoImageSurface.fromImage(image));

        var pattern = CairoPattern.createRadial(size / 2, size / 2, 0, size / 2, size / 2, radius);
        pattern.addColorStopRGBA(ratio, 1, 0, 0, 1); // BGRA
        pattern.addColorStopRGBA(    1, 0, 0, 0, 1); // BGRA
        cairo.source = pattern;
        cairo.arc(size / 2, size / 2, 40, 0, Math.PI * 2);
        cairo.fill();

        for (ike in 0...4) Blur2D.apply(image, blurAmount, blurAmount);

        return image;
    }
}
