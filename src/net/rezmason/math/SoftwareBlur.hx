package net.rezmason.math;

typedef Rect = {x:Float, y:Float, width:Float, height:Float};
typedef Accessor = Float->Float->Array<Float>;
typedef Modifier = Float->Float->Array<Float>->Void;

// Not perfect. Seeing slightly asymmetrical results.

class SoftwareBlur {
    public static function apply(blurX:Float, blurY:Float, bounds:Rect, accessor:Accessor, modifier:Modifier) {
        var blurRange = Math.sqrt(blurX * blurX + blurY * blurY);
        var kernelSize = Std.int(blurRange);
        var dx = blurX / blurRange;
        var dy = blurY / blurRange;
        var startX = -blurX / 2;
        var startY = -blurY / 2;

        var sigma = blurRange / 3;
        var coefficient = 1 / Math.sqrt(2 * Math.PI * sigma * sigma);
        var total = 0.0;
        var kernel = [];
        for (ike in 0...kernelSize) {
            var x = ike - kernelSize / 2;
            var g = coefficient * Math.pow(2.7182818284, -(x * x / (2 * sigma * sigma)));
            kernel[ike] = g;
            total += g;
        }
        for (ike in 0...kernelSize) kernel[ike] /= total;
        
        var numValues = accessor(bounds.x, bounds.y).length;
        
        var y = 0;
        while (y < bounds.width) {
            var x = 0;
            while (x < bounds.width) {
                var result = [for (ike in 0...numValues) 0.0];
                for (ike in 0...kernelSize) {
                    var mag = kernel[ike];
                    var sample = accessor(
                        bounds.x + x + startX + ike * dx,
                        bounds.y + y + startY + ike * dy
                    );
                    for (jen in 0...numValues) result[jen] += sample[jen] * mag;
                }
                modifier(bounds.x + x, bounds.y + y, result);
                x++;
            }
            y++;
        }
    }
}
