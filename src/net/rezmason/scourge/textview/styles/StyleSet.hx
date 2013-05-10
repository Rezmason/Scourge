package net.rezmason.scourge.textview.styles;

using Lambda;

class StyleSet {

    public inline static var SIGIL:String = "§";

    static var whitespaceReg:EReg = ~/([,\s]+)/g;
    static var colonReg:EReg = ~/\s*:\s*/g;
    static var styleTagsReg:EReg = ~/§\{[^\}]*\}/g;

    var styleIDs:Int;
    var stylesByIndex:Array<Style>;
    var allStyles:Array<Style>;

    public var defaultStyle(default, null):Style;
    var cleanStyle:Style;

    public function new():Void {
        cleanStyle = Style.create(["r:1", "g:1", "b:1", "i:0", "s:1", "p:0"]);
    }

    public function extractFromText(input:String, defaultStyle:Style = null):String {
        if (defaultStyle == null) defaultStyle = cleanStyle;
        defaultStyle.removeAllGlyphs();
        this.defaultStyle = defaultStyle;
        styleIDs = 0;
        stylesByIndex = [];
        allStyles = [];

        var tags:Array<Array<String>> = extractTags(input);
        var stylesByID:Map<String, Style> = convertDeclarativeTags(tags);
        stylesByID[""] = defaultStyle;
        resolveStyleDependencies(stylesByID);
        convertReferenceTags(tags, stylesByID);

        stylesByIndex.unshift(defaultStyle);

        return styleTagsReg.replace(input, SIGIL);
    }

    public function getStyleByIndex(index:Int):Style {
        var style:Style = stylesByIndex[index];
        if (style == null) style = defaultStyle;
        return style;
    }

    public function removeAllGlyphs():Void {
        for (style in allStyles) style.removeAllGlyphs();
    }

    public function updateGlyphs(delta:Float):Void {
        for (style in allStyles) style.updateGlyphs(delta);
    }

    inline function extractTags(input:String):Array<Array<String>> {
        var tags:Array<Array<String>> = [];

        var styleStrings:Array<String> = input.split('${SIGIL}{');
        if (styleStrings.length > 1) {
            for (str in styleStrings) {
                if (str.length == 0) continue;
                var tagEndIndex:Int = str.indexOf("}");
                if (tagEndIndex == -1) throw 'You left a style tag open, friend: ( $str )';
                tags.push(cleanTag(str.substr(0, tagEndIndex)));
            }
        }

        return tags;
    }

    inline function convertDeclarativeTags(tags:Array<Array<String>>):Map<String, Style> {
        var stylesByID:Map<String, Style> = new Map();

        for (ike in 0...tags.length) {
            var tag:Array<String> = tags[ike];
            if (tag.length > 1 || tag[0].indexOf(":") != -1) {
                var style:Style = Style.create(tag);

                if (style.name == null) style.name = "style" + styleIDs++;
                stylesByIndex[ike] = style;
                allStyles.push(style);
                stylesByID[style.name] = style;

                tags[ike] = null;
            }
        }

        return stylesByID;
    }

    inline function resolveStyleDependencies(stylesByID:Map<String, Style>):Void {
        for (style in allStyles) {
            var topStyle:Style = style;
            var dependencyStack:Array<String> = [];
            while (true) {
                dependencyStack.push(topStyle.name);

                if (topStyle.basis == null) break;
                if (dependencyStack.has(topStyle.basis)) {
                    throw 'Cyclical style dependency, pal: ( $dependencyStack )';
                }

                topStyle = stylesByID[topStyle.basis];
                if (topStyle == null) break;
            }

            while (dependencyStack.length > 0) {
                topStyle = stylesByID[dependencyStack.pop()];

                if (topStyle != null) {
                    Style.inherit(topStyle, stylesByID[topStyle.basis]);
                    topStyle.basis = null;
                }
            }
        }

        for (style in allStyles) Style.inherit(style, defaultStyle);
        allStyles.push(defaultStyle);
    }

    inline function convertReferenceTags(tags:Array<Array<String>>, stylesByID:Map<String, Style>):Void {
        for (ike in 0...tags.length) {
            var tag:Array<String> = tags[ike];
            if (tag != null) {
                var style:Style = stylesByID[tag[0]];
                if (style == null) style = defaultStyle;
                stylesByIndex[ike] = style;
            }
        }
    }

    inline function cleanTag(tagString:String):Array<String> {
        tagString = whitespaceReg.replace(tagString, " ");
        tagString = colonReg.replace(tagString, ":");
        tagString = StringTools.trim(tagString);

        return tagString.split(" ");
    }
}
