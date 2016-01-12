package net.rezmason.hypertype.core;

import lime.Assets;
import net.rezmason.utils.Zig;

class FontManager {
    var fonts:Map<String, GlyphFont>;
    public var defaultFont(default, set):GlyphFont;
    public var onFontChange(default, null):Zig<GlyphFont->Void>;

    public function new(fontNames:Array<String>):Void {
        fonts = new Map();
        for (name in fontNames) fonts[name] = new GlyphFont(Assets.getBytes('sdffonts/${name}.htf'));
        onFontChange = new Zig();
        if (fontNames.length > 0) defaultFont = fonts[fontNames[0]];
    }

    public function fontNames() return [for (name in fonts.keys()) name];
    public function getFontByName(name) return fonts[name];

    public function set_defaultFont(font) {
        defaultFont = font;
        onFontChange.dispatch(defaultFont);
        return font;
    }
}
