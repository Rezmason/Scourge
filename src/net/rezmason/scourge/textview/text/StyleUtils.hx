package net.rezmason.scourge.textview.text;

import haxe.Utf8;
import net.rezmason.scourge.textview.text.Sigil.*;

using Lambda;

typedef ParsedOutput = {
    var text:String;
    var newStyles:Array<Style>;
    var stylesByIndex:Array<Style>;
}

class StyleUtils {

    public static var defaultStyle(default, null):Style = makeDefaultStyle();

    public static var styleTypes:Map<String, Class<Style>> = [
        STYLE => Style,
        ANIMATED_STYLE => AnimatedStyle,
        BUTTON_STYLE => ButtonStyle,
        // INPUT_STYLE => InputStyle,
    ];

    public inline static function defaultStyleTag():Dynamic return {name:'', r:1, g:1, b:1, i:0, f:0.5, s:1, p:0};

    public static inline function parse(input:String, lookup:Map<String, Style>, nextMouseID:Int):ParsedOutput {
        var newStyles:Array<Style> = [];
        var stylesByIndex:Array<Style> = [defaultStyle];

        var left:String = '';
        var right:String = input;
        while (right.length > 0) {
            var startIndex:Int = -1;
            var styleType:Class<Style> = null;

            // Find the next sigil

            for (sigil in [STYLE, ANIMATED_STYLE, BUTTON_STYLE, INPUT_STYLE]) {
                var index:Int = right.indexOf(sigil);
                if (index != -1 && (startIndex == -1 || startIndex > index)) {
                    startIndex = index;
                    styleType = StyleUtils.styleTypes[sigil];
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
                    var style:Style = makeStyle(styleType, right.substr(0, endIndex + 1), lookup, nextMouseID);
                    if (style != defaultStyle && lookup[style.name] == null) {
                        lookup[style.name] = style;
                        newStyles.push(style);
                        nextMouseID++;
                    }
                    stylesByIndex.push(style);
                    right = right.substr(endIndex, right.length);
                    right = Utf8.sub(right, 1, Utf8.length(right));
                }
            } else {
                break;
            }
        }

        // Resolve bases

        for (topStyle in newStyles) {
            var style:Style = topStyle;
            var dependencyStack:Array<String> = [];
            while (true) {
                dependencyStack.push(style.name);

                if (style.basis == null) break;
                if (dependencyStack.has(style.basis)) {
                    throw 'Cyclical style dependency, pal: ( $dependencyStack )';
                }

                style = lookup[style.basis];
                if (style == null) break;
            }

            while (dependencyStack.length > 0) {
                style = lookup[dependencyStack.pop()];
                if (style.basis != null) style.inherit(lookup[style.basis]);
            }
        }

        for (style in newStyles) {
            style.connectBases(lookup);
            style.flatten();
        }

        // trace('${newStyles.length} styles created.');

        return {text:left + right, newStyles:newStyles, stylesByIndex:stylesByIndex};
    }

    public inline static function makeStyle(styleType:Class<Style>, input:String, lookup:Map<String, Style>, index:Int):Style {

        input = Utf8.sub(input, 1, Utf8.length(input)    ); // Remove leading  '{'
        input = Utf8.sub(input, 0, Utf8.length(input) - 1); // Remove trailing '}'

        var name:String = input.indexOf(':') == -1 ? input : StyleUtils.parseName(input);
        if (name == null) throw 'Style declaration must include name, chief: ( $input )';

        var style:Style = lookup[name];
        if (style == null) style = Type.createInstance(styleType, [StyleUtils.parseTag(input), index]);

        return style;
    }

    public inline static function makeDefaultStyle():Style {
        var style:Style = new Style(StyleUtils.defaultStyleTag());
        style.flatten();
        return style;
    }

    public inline static function parseTag(input:String):Dynamic {

        var tag:Dynamic = {};
        var left:String = '';
        var right:String = input;

        // Remove spaces

        while (right.length > 0) {
            var startIndex:Int = right.indexOf(' ');
            if (startIndex == -1) break;
            left = left + right.substr(0, startIndex);
            right = right.substr(startIndex + 1, right.length);
        }

        right = left + right;

        while (right.length > 0) {

            // Search for colon
            var firstColonIndex:Int = right.indexOf(':');
            if (firstColonIndex == -1) break;

            var field:String = right.substr(0, firstColonIndex);
            var value:Dynamic = null;

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
                valueString = valueString.substr(1, valueString.length);
                valueString = valueString.substr(0, valueString.length - 1);
                while (valueString.length > 0) {
                    var commaIndex:Int = valueString.indexOf(',');
                    if (commaIndex == -1) {
                        valueArray.push(valueString);
                        valueString = '';
                    } else {
                        valueArray.push(valueString.substr(0, commaIndex));
                        valueString = valueString.substr(commaIndex + 1, valueString.length);
                    }
                }
                value = valueArray;
            } else {
                value = valueString;
            }

            Reflect.setField(tag, field, value);
        }

        return tag;
    }

    public inline static function parseName(input:String):String {
        var output:String = null;
        var index:Int = input.indexOf('name');
        if (index != -1) {
            output = Utf8.sub(input, index, input.length);
            var splitIndex:Int = output.indexOf(':');
            output = Utf8.sub(output, splitIndex + 1, output.length);
            splitIndex = output.indexOf(',');
            if (splitIndex != -1) output = Utf8.sub(output, 0, splitIndex);
        }
        return output;
    }
}
