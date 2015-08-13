package net.rezmason.scourge.textview.core;

import lime.Assets;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.utils.display.FlatFont;
import net.rezmason.utils.Zig;

class FontManager {
    var fontTextures:Map<String, GlyphTexture>;
    public var defaultFont(default, set):GlyphTexture;
    public var onFontChange(default, null):Zig<GlyphTexture->Void>;

    public function new(fontNames:Array<String>):Void {
        fontTextures = new Map();
        for (name in fontNames) {
            var path:String = 'flatfonts/${name}_flat';
            var font:FlatFont = new FlatFont(Assets.getImage('$path.png'), Assets.getText('$path.json'));
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
