package net.rezmason.hypertype.core;

import lime.graphics.Image;
import net.rezmason.gl.ImageTexture;
#if debug_graphics 
    import lime.graphics.cairo.CairoImageSurface;
    import lime.graphics.cairo.Cairo;
#end

class DebugDisplay {
    public var texture(default, null):ImageTexture;
    public var image(default, null):Image;
    #if debug_graphics 
        var debugSurface:CairoImageSurface;
        public var cairo(default, null):Cairo;
    #end
    
    public function new() {
        image = new Image(null, 0, 0, 1, 1, 0x00000000);
        texture = new ImageTexture(image);
        #if debug_graphics 
            debugSurface = CairoImageSurface.fromImage(image);
            cairo = new Cairo(debugSurface);
        #end
    }

    public function resize(width, height) {
        image.resize(width, height);
        #if debug_graphics 
            debugSurface = CairoImageSurface.fromImage(image);
            @:privateAccess cairo.recreate(debugSurface);
            cairo.identityMatrix();
            if (width > height) {
                cairo.translate((width - height) / 2, 0);
                cairo.scale(height, height);
            } else {
                cairo.translate(0, (height - width) / 2);
                cairo.scale(width, width);
            }
            cairo.translate(0.5, 0.5);
        #end
    }

    public function refresh() (cast texture).update();
}
