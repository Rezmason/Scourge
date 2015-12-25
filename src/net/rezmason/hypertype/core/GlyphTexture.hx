package net.rezmason.hypertype.core;

import net.rezmason.utils.display.FlatFont;
import net.rezmason.gl.Texture;
import net.rezmason.gl.GLSystem;
import net.rezmason.utils.santa.Present;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var font(default, null):FlatFont;
    public var name(default, null):String;

    public function new(name:String, font:FlatFont):Void {
        this.name = name;
        this.font = font;
        var glSys:GLSystem = new Present(GLSystem);
        texture = glSys.createHalfFloatTexture(font.width, font.height, font.textureData, true);
    }
}
