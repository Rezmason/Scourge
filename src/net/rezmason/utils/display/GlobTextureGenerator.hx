package net.rezmason.utils.display;

import de.polygonal.core.math.random.ParkMiller;

import lime.graphics.Image;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoPattern;


class GlobTextureGenerator {

    public static function makeTexture(size:Int):Image {

        var image = new Image(null, 0, 0, size, size);
        image.fillRect(image.rect, 0x000000FF, BGRA32);
        
        var cairo = new Cairo(CairoImageSurface.fromImage(image));
        var rng = new ParkMiller();

        cairo.setSourceRGBA(0, 1, 0, 1); // BGRA
        for (ike in 0...1000) {
            var theta:Float = rng.randomFloat() * Math.PI * 2;
            var rad:Float = Math.pow(rng.randomFloat(), 0.5) * 0.5 * size;
            cairo.arc(
                size / 2 + Math.cos(theta) * rad, 
                size / 2 + Math.sin(theta) * rad, 
                rng.randomFloat() * size / 100, 0, Math.PI * 2
            );
            cairo.fill();
        }

        for (ike in 0...4) Blur2D.apply(image, 10, 10);

        var pattern = CairoPattern.createRadial(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
        pattern.addColorStopRGBA(0.0, 0, 0, 0, 1); // BGRA
        pattern.addColorStopRGBA(0.5, 0, 0, 0, 0); // BGRA
        pattern.addColorStopRGBA(0.9, 0, 0, 0, 0); // BGRA
        pattern.addColorStopRGBA(1.0, 0, 0, 0, 1); // BGRA
        cairo.source = pattern;
        cairo.paint();
        
        return image;
    }
}
