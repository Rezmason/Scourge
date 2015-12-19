package net.rezmason.hypertype.core;

import haxe.io.Bytes;
import lime.Assets;
import net.rezmason.hypertype.core.GlyphTexture;
import net.rezmason.utils.Zig;
import net.rezmason.utils.display.FlatFont;

class FontManager {
    var fontTextures:Map<String, GlyphTexture>;
    public var defaultFont(default, set):GlyphTexture;
    public var onFontChange(default, null):Zig<GlyphTexture->Void>;

    public function new(fontNames:Array<String>):Void {
        fontTextures = new Map();
        for (name in fontNames) {
            var byteArray = Assets.getBytes('flatfonts/${name}.htf');
            var bytes = null;
            #if flash
                bytes = Bytes.ofData(byteArray);
            #elseif js
                bytes = Bytes.ofData(byteArray.__getBuffer());
            #else
                bytes = byteArray;
            #end
            var font:FlatFont = new FlatFont(bytes);
            fontTextures[name] = cast new GlyphTexture(name, font);
        }

        onFontChange = new Zig();
        if (fontNames.length > 0) defaultFont = fontTextures[fontNames[0]];

    }

    public function fontNames():Array<String> return [for (fontTexture in fontTextures) fontTexture.name];

    public function getFontByName(name:String):GlyphTexture return fontTextures[name];

    public function set_defaultFont(font:GlyphTexture):GlyphTexture {
        if (fontTextures[font.name] == font) defaultFont = font;
        onFontChange.dispatch(defaultFont);
        return defaultFont;
    }
}
