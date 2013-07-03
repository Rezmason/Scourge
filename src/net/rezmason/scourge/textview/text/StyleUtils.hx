package net.rezmason.scourge.textview.text;

import haxe.Utf8;
import net.rezmason.scourge.textview.text.Sigil.*;

class StyleUtils {

    public static var styleTypes:Map<String, Class<Style>> = [
        STYLE => Style,
        ANIMATED_STYLE => AnimatedStyle,
        BUTTON_STYLE => ButtonStyle,
        INPUT_STYLE => InputStyle,
    ];

    public inline static function defaultStyleTag():Dynamic return {r:1, g:1, b:1, i:0, s:1, p:0};

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
