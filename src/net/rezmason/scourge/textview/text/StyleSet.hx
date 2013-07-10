package net.rezmason.scourge.textview.text;

import haxe.Utf8;
import net.rezmason.scourge.textview.text.Sigil.*;

using Lambda;

class StyleSet {

    var allStyles:Array<Style>;
    var newStyles:Array<Style>;
    var stylesByName:Map<String, Style>;

    public var defaultStyle(default, null):Style;

    public function new():Void {
        defaultStyle = new Style('', null, StyleUtils.defaultStyleTag());
        defaultStyle.flatten();
    }

    public inline function extract(input:String, bucket:Array<Style> = null, refreshStyles:Bool = false):String {

        refreshStyles = refreshStyles || allStyles == null;

        defaultStyle.removeAllGlyphs();
        newStyles = [];

        if (refreshStyles) {
            if (allStyles != null) for (style in allStyles) style.removeAllGlyphs();
            allStyles = [];
            stylesByName = new Map();
            stylesByName[defaultStyle.name] = defaultStyle;
        }

        allStyles.remove(defaultStyle);

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
                    var style:Style = makeStyle(styleType, right.substr(0, endIndex + 1));
                    if (bucket != null) bucket.push(style);
                    right = right.substr(endIndex, right.length);
                    right = Utf8.sub(right, 1, Utf8.length(right));
                }
            } else {
                break;
            }
        }

        allStyles.push(defaultStyle);
        if (bucket != null) bucket.unshift(defaultStyle);
        flatten();

        // trace('${newStyles.length} styles created.');

        return left + right;
    }

    public inline function getStyleByMouseID(id:Int):Style return allStyles[id];
    public inline function getStyleByName(name:String):Style return stylesByName[name];
    public inline function removeAllGlyphs():Void  for (style in allStyles) style.removeAllGlyphs();
    public inline function updateGlyphs(delta:Float):Void for (style in allStyles) style.updateGlyphs(delta);

    inline function flatten():Void {

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

                style = stylesByName[style.basis];
                if (style == null) break;
            }

            while (dependencyStack.length > 0) {
                style = stylesByName[dependencyStack.pop()];
                if (style.basis != null) style.inherit(stylesByName[style.basis]);
            }
        }

        for (style in newStyles) {
            style.connectBases(stylesByName);
            style.flatten();
        }
    }

    inline function makeStyle(styleType:Class<Style>, input:String):Style {

        input = Utf8.sub(input, 1, Utf8.length(input)    ); // Remove leading  '{'
        input = Utf8.sub(input, 0, Utf8.length(input) - 1); // Remove trailing '}'

        var name:String = input.indexOf(':') == -1 ? input : StyleUtils.parseName(input);
        if (name == null) {
            // name = 'style${allStyles.length}';
            throw 'Style declaration must include name, chief: ( $input )';
        }

        var style:Style = stylesByName[name];
        if (style == null) {
            var dec:Dynamic = StyleUtils.parseTag(input);
            style = Type.createInstance(styleType, [name, dec.basis, dec, allStyles.length]);
            stylesByName[name] = style;
            allStyles.push(style);
            newStyles.push(style);
        }

        if (style == null) {
            style = defaultStyle;
        }

        return style;
    }
}
