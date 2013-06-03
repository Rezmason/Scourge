package net.rezmason.scourge.textview.styles;

import haxe.Utf8;
import net.rezmason.scourge.textview.styles.Sigil.*;

using haxe.JSON;
using Lambda;
using Type;

class StyleSet {

    static var stringReg:EReg = ~/([^,\s:\\"\[\]]+)/g;
    static var styleTagsReg:EReg = new EReg('[$STYLE $ANIMATED_STYLE $BUTTON_STYLE $INPUT_STYLE]\\{[^\\}]*\\}', 'g');

    var styleTypes:Map<String, Class<Style>>;

    var styleMouseID:Int;
    var stylesByIndex:Array<Style>;
    var allStyles:Array<Style>;

    public var defaultStyle(default, null):Style;
    var cleanStyle:Style;

    public function new():Void {
        cleanStyle = new Style("", null, {r:1, g:1, b:1, i:0, s:1, p:0});

        styleTypes = new Map();
        styleTypes.set(STYLE, Style);
        styleTypes.set(ANIMATED_STYLE, AnimatedStyle);
        styleTypes.set(BUTTON_STYLE, ButtonStyle);
        styleTypes.set(INPUT_STYLE, InputStyle);
    }

    public function extractFromText(input:String, defaultStyle:Style = null):String {

        if (defaultStyle == null) defaultStyle = cleanStyle;
        defaultStyle.removeAllGlyphs();
        defaultStyle.flatten();
        this.defaultStyle = defaultStyle;
        styleMouseID = 0;
        stylesByIndex = [];
        allStyles = [];

        var tags:Array<StyleTag> = extractTags(input);
        var stylesByID:Map<String, Style> = convertDeclarativeTags(tags);
        stylesByID[defaultStyle.name] = defaultStyle;
        resolveStyleDependencies(stylesByID);
        for (style in allStyles) style.flatten();
        allStyles.push(defaultStyle);
        convertReferenceTags(tags, stylesByID);

        //for (style in allStyles) trace(style);

        stylesByIndex.unshift(defaultStyle);

        return styleTagsReg.replace(input, STYLE);
    }

    public function getStyleByIndex(index:Int):Style {
        var style:Style = stylesByIndex[index];
        if (style == null) style = defaultStyle;
        return style;
    }

    public function getStyleByMouseID(id:Int):Style {
        return allStyles[id];
    }

    public function removeAllGlyphs():Void {
        for (style in allStyles) style.removeAllGlyphs();
    }

    public function updateGlyphs(delta:Float):Void {
        for (style in allStyles) style.updateGlyphs(delta);
    }

    inline function extractTags(input:String):Array<StyleTag> {

        var tags:Array<StyleTag> = [];

        while(styleTagsReg.match(input)) {
            var pos = styleTagsReg.matchedPos();
            tags.push(parseTag(input.substr(pos.pos, pos.len)));
            input = input.substr(pos.pos + pos.len);
        }

        return tags;
    }

    inline function convertDeclarativeTags(tags:Array<StyleTag>):Map<String, Style> {
        var stylesByID:Map<String, Style> = new Map();

        for (ike in 0...tags.length) {
            switch (tags[ike]) {
                case DeclTag(s, dec):
                    var name:String = dec.name;
                    if (name == null) name = "style" + styleMouseID;
                    var style:Style = styleTypes[s].createInstance([name, dec.basis, dec, styleMouseID]);
                    allStyles.push(style);
                    stylesByID[name] = style;
                    stylesByIndex[ike] = style;
                    styleMouseID++;
                case _:
            }
        }

        return stylesByID;
    }

    inline function resolveStyleDependencies(stylesByID:Map<String, Style>):Void {
        for (topStyle in allStyles) {
            var style:Style = topStyle;
            var dependencyStack:Array<String> = [];
            while (true) {
                dependencyStack.push(style.name);

                if (style.basis == null) break;
                if (dependencyStack.has(style.basis)) {
                    throw 'Cyclical style dependency, pal: ( $dependencyStack )';
                }

                style = stylesByID[style.basis];
                if (style == null) break;
            }

            while (dependencyStack.length > 0) {
                style = stylesByID[dependencyStack.pop()];
                style.inherit(stylesByID[style.basis]);
            }
        }

        // Some styles have more complex dependencies. We resolve them here.
        for (style in allStyles) style.connectBases(stylesByID);
    }

    inline function convertReferenceTags(tags:Array<StyleTag>, stylesByID:Map<String, Style>):Void {
        for (ike in 0...tags.length) {
            switch (tags[ike]) {
                case RefTag(s, ref):
                    var style:Style = stylesByID[ref];
                    if (style == null) style = defaultStyle;
                    stylesByIndex[ike] = style;
                case _:
            }
        }
    }

    inline function parseTag(tagString:String):StyleTag {
        // trace(tagString);
        var sigil:String = tagString.charAt(0);
        tagString = tagString.substr(2).substr(0, -1); // Remove leading '§{' and trailing '}'
        var tag:StyleTag = null;
        if (tagString.indexOf(":") == -1) tag = RefTag(sigil, tagString); // Tags with no declared properties are obviously references
        else tag = DeclTag(sigil, ("{" + stringReg.replace(tagString, '"$1"') + "}").parse()); // Turn the string into JSON and parse it
        return tag;
    }
}
