package net.rezmason.hypertype.core;

import net.rezmason.utils.display.SDFFont;
import net.rezmason.gl.Texture;
import net.rezmason.gl.GLSystem;
import net.rezmason.utils.santa.Present;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var font(default, null):SDFFont;
    public var name(default, null):String;

    public function new(name:String, font:SDFFont):Void {
        this.name = name;
        this.font = font;
        var glSys:GLSystem = new Present(GLSystem);
        texture = glSys.createHalfFloatTexture(font.width, font.height, font.textureData, true);
    }
}
