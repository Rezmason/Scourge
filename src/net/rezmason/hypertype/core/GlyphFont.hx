package net.rezmason.hypertype.core;

import lime.math.Vector4;
import net.rezmason.gl.HalfFloatTexture;
import net.rezmason.utils.display.SDFFont;

class GlyphFont extends SDFFont {

    public var texture(default, null):HalfFloatTexture;
    public var glyphData(default, null):Vector4;
    public var sdfData(default, null):Vector4;

    public function new(htf) {
        super(htf);
        texture = new HalfFloatTexture(width, height, textureData, true);
        glyphData = new Vector4(width, height, glyphWidth, glyphHeight);
        var sdfWidthScale  = sdfCoreWidth  / (sdfCoreWidth  + 2 * sdfRange);
        var sdfHeightScale = sdfCoreHeight / (sdfCoreHeight + 2 * sdfRange);
        sdfData = new Vector4(sdfWidthScale, sdfHeightScale, sdfRange, glyphRatio);
    }
}
