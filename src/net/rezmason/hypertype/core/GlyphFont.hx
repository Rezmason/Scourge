package net.rezmason.hypertype.core;

import net.rezmason.gl.HalfFloatTexture;
import net.rezmason.utils.display.SDFFont;

class GlyphFont extends SDFFont {

    public var texture(default, null):HalfFloatTexture;

    public function new(htf) {
        super(htf);
        texture = new HalfFloatTexture(width, height, textureData, true);
    }
}
