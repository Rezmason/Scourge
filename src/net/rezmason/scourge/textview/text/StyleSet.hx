package net.rezmason.scourge.textview.text;

import haxe.Utf8;
import net.rezmason.scourge.textview.text.Sigil.*;

using Lambda;
using Type;

class StyleSet {

    static var styleTypes:Map<String, Class<Style>> = [
        STYLE => Style,
        ANIMATED_STYLE => AnimatedStyle,
        BUTTON_STYLE => ButtonStyle,
        INPUT_STYLE => InputStyle,
    ];

    var numDeclTags:Int;
    var stylesByIndex:Array<Style>;
    var allStyles:Array<Style>;
    var newStyles:Array<Style>;
    var stylesByName:Map<String, Style>;
    var tags:Array<StyleTag>;

    public var defaultStyle(default, null):Style;

    public function new():Void {
        defaultStyle = new Style('', null, {r:1, g:1, b:1, i:0, s:1, p:0});
    }

    public function extractFromText(input:String, refreshStyles:Bool = false):String {

        refreshStyles = refreshStyles || allStyles == null;

        defaultStyle.removeAllGlyphs();
        defaultStyle.flatten();
        numDeclTags = 0;
        stylesByIndex = [];
        newStyles = [];
        tags = [];

        if (refreshStyles) {
            allStyles = [];
            stylesByName = new Map();
            stylesByName[defaultStyle.name] = defaultStyle;
        }

        var output:String = extractTags(input);
        convertDeclarativeTags();
        resolveStyleDependencies();
        for (style in newStyles) style.flatten();
        if (refreshStyles) allStyles.push(defaultStyle);
        convertReferenceTags();

        // trace('${newStyles.length} new styles.');

        stylesByIndex.unshift(defaultStyle);

        return output;
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

    inline function convertDeclarativeTags():Void {
        var declTagItr:Int = 0;
        for (ike in 0...tags.length) {
            switch (tags[ike]) {
                case DeclTag(s, name, dec):
                    var style:Style = styleTypes[s].createInstance([name, dec.basis, dec, declTagItr]);
                    allStyles.push(style);
                    newStyles.push(style);
                    stylesByName[name] = style;
                    stylesByIndex[ike] = style;
                    declTagItr++;
                case _:
            }
        }
    }

    inline function extractTags(input:String):String {

        var left:String = '';
        var right:String = input;
        while (right.length > 0) {
            var startIndex:Int = -1;
            var tagSigil:String = '';

            // Find the next sigil

            for (sigil in [STYLE, ANIMATED_STYLE, BUTTON_STYLE, INPUT_STYLE]) {
                var index:Int = right.indexOf(sigil);
                if (index != -1 && (startIndex == -1 || startIndex > index)) {
                    startIndex = index;
                    tagSigil = sigil;
                }
            }

            // Find the close brace

            if (startIndex != -1) {
                if (startIndex > 0) left = left + right.substr(0, startIndex);
                left = left + STYLE;

                right = right.substr(startIndex, right.length);
                right = Utf8.sub(right, 1, Utf8.length(right));

                var endIndex:Int = right.indexOf('}');
                if (endIndex != -1) {
                    tags.push(makeTag(tagSigil + right.substr(0, endIndex + 1)));
                    right = right.substr(endIndex, right.length);
                    right = Utf8.sub(right, 1, Utf8.length(right));
                }
            } else {
                break;
            }
        }

        return left + right;
    }

    inline function parseTag(input:String):Dynamic {

        var tag:Dynamic = {};

        var left:String = '';
        var right:String = input;

        // Remove spaces

        while (right.length > 0) {
            var startIndex:Int = right.indexOf(' ');
            if (startIndex != -1) {
                left = left + right.substr(0, startIndex);
                right = right.substr(startIndex + 1, right.length);
            } else {
                break;
            }
        }

        right = left + right;
        left = '';

        while (right.length > 0) {

            // Search for colon
            var firstColonIndex:Int = right.indexOf(':');

            if (firstColonIndex != -1) {

                var field:String = right.substr(0, firstColonIndex);
                var value:Dynamic = null;

                // left = left + '"' + right.substr(0, firstColonIndex) + '":';
                right = right.substr(firstColonIndex + 1, right.length);

                // Search for second colon
                var valueString:String = '';
                var secondColonIndex:Int = right.indexOf(':');
                if (secondColonIndex == -1) {
                    valueString = right;
                    right = '';
                } else {
                    // Search for last comma before second colon
                    var lastCommaIndex:Int = right.substr(0, secondColonIndex).lastIndexOf(',');
                    valueString = right.substr(0, lastCommaIndex);
                    right = right.substr(lastCommaIndex + 1, right.length);
                }

                if (valueString.indexOf('[') == 0) {
                    var valueArray:Array<String> = [];
                    // array of strings ; replace commas with "," and wrap in [" "]
                    valueString = valueString.substr(1, valueString.length);
                    valueString = valueString.substr(0, valueString.length - 1);
                    // var seq:String = '';
                    while (valueString.length > 0) {
                        var commaIndex:Int = valueString.indexOf(',');
                        if (commaIndex == -1) {
                            // seq = seq + '"$valueString"';
                            valueArray.push(valueString);
                            valueString = '';
                        } else {
                            valueArray.push(valueString.substr(0, commaIndex));
                            // seq = seq + '"' + valueString.substr(0, commaIndex) + '",';
                            valueString = valueString.substr(commaIndex + 1, valueString.length);
                        }
                    }
                    // valueString = '[$seq]';
                    value = valueArray;
                } else {
                    value = valueString;
                    // valueString = '"$valueString"';
                }

                // left = left + valueString;
                Reflect.setField(tag, field, value);

                // if (secondColonIndex != -1) left = left + ',';

            } else {
                break;
            }
        }

        // left = '{$left}';

        return tag;
    }

    function resolveStyleDependencies():Void {
        for (topStyle in newStyles) {
            var style:Style = topStyle;
            var dependencyStack:Array<String> = [];
            while (true) {
                dependencyStack.push(style.name);

                if (style.basis == null) break;
                if (dependencyStack.has(style.basis)) {
                    throw 'Cyclical style dependency, pal: ( $dependencyStack )';
                }

                style = stylesByName[style.basis];
                if (style == null) break;
            }

            while (dependencyStack.length > 0) {
                style = stylesByName[dependencyStack.pop()];
                if (style.basis != null) style.inherit(stylesByName[style.basis]);
            }
        }

        // Some styles have more complex dependencies. We resolve them here.
        for (style in newStyles) style.connectBases(stylesByName);
    }

    inline function convertReferenceTags():Void {
        for (ike in 0...tags.length) {
            switch (tags[ike]) {
                case RefTag(s, ref):
                    var style:Style = stylesByName[ref];
                    if (style == null) style = defaultStyle;
                    stylesByIndex[ike] = style;
                case _:
            }
        }
    }

    inline function makeTag(tagString:String):StyleTag {

        var sigil:String = Utf8.sub(tagString, 0, 1);
        tagString = Utf8.sub(tagString, 2, Utf8.length(tagString)); // Remove leading '§{'
        tagString = Utf8.sub(tagString, 0, Utf8.length(tagString) - 1); // Remove trailing '}'

        var tag:StyleTag = null;
        if (tagString.indexOf(':') == -1) {
            tag = RefTag(sigil, tagString); // Tags with no declared properties are obviously references
        } else {
            var nameIndex:Int = tagString.indexOf('name');
            var name:String = '';
            if (nameIndex != -1) {
                name = Utf8.sub(tagString, nameIndex, tagString.length);

                var splitIndex:Int = name.indexOf(':');
                name = Utf8.sub(name, splitIndex + 1, name.length);
                splitIndex = name.indexOf(',');
                if (splitIndex != -1) name = Utf8.sub(name, 0, splitIndex);
            } else {
                name = 'style$numDeclTags';
            }
            numDeclTags++;

            if (stylesByName[name] != null) {
                tag = RefTag(sigil, name);
            } else {
                tag = DeclTag(sigil, name, parseTag(tagString));
            }
        }

        return tag;
    }
}
