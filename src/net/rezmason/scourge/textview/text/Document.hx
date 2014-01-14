package net.rezmason.scourge.textview.text;

import haxe.Utf8;
import net.rezmason.scourge.textview.text.Sigil.*;

class Document {

    var allStyles:Array<Style>;
    var stylesByName:Map<String, Style>;
    public var styledText(default, null):String;
    var stylesByIndex:Array<Style>;

    public function new():Void {
        clear();
    }

    public inline function clear():Void {
        if (allStyles != null) for (style in allStyles) style.removeAllGlyphs();
        allStyles = [];
        stylesByIndex = [];
        stylesByName = new Map();
        stylesByName[StyleUtils.defaultStyle.name] = StyleUtils.defaultStyle;
    }

    public inline function loadStyles(input:String):Void {
        StyleUtils.defaultStyle.removeAllGlyphs();

        allStyles = allStyles.concat(StyleUtils.parse(input, stylesByName, allStyles.length).newStyles);

        allStyles.remove(StyleUtils.defaultStyle);
        allStyles.push(StyleUtils.defaultStyle);
    }

    public inline function setText(input:String):Void {
        StyleUtils.defaultStyle.removeAllGlyphs();
        allStyles.remove(StyleUtils.defaultStyle);

        var result = StyleUtils.parse(input, stylesByName, allStyles.length);
        styledText = result.text;
        allStyles = allStyles.concat(result.newStyles);
        stylesByIndex = result.stylesByIndex;

        allStyles.push(StyleUtils.defaultStyle);
    }

    public inline function getStyleByIndex(index:Int):Style return stylesByIndex[index];
    public inline function getStyleByMouseID(id:Int):Style return allStyles[id];
    public inline function getStyleByName(name:String):Style return stylesByName[name];
    public inline function removeAllGlyphs():Void  for (style in allStyles) style.removeAllGlyphs();
    public inline function updateGlyphs(delta:Float):Void for (style in allStyles) style.updateGlyphs(delta);
}
