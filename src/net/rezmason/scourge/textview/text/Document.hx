package net.rezmason.scourge.textview.text;

class Document {

    public var styledText(default, null):String;
    var styles:Array<Style>;
    var stylesByName:Map<String, Style>;
    var spans:Array<Span>;
    var allSpans:Array<Span>;

    public function new():Void {
        clear();
    }

    public inline function clear():Void {
        styles = [];
        spans = [];
        allSpans = [];
        stylesByName = new Map();
        stylesByName[StyleUtils.defaultStyle.name] = StyleUtils.defaultStyle;
    }

    public inline function loadStyles(input:String):Void {
        styles.remove(StyleUtils.defaultStyle);

        styles = styles.concat(StyleUtils.parse(input, stylesByName, styles.length).newStyles);

        styles.push(StyleUtils.defaultStyle);
    }

    public inline function setText(input:String):Void {

        if (spans != null) for (span in spans) span.removeAllGlyphs();
        // TODO: pool spans

        styles.remove(StyleUtils.defaultStyle);

        var result = StyleUtils.parse(input, stylesByName, 1);
        styledText = result.text;
        styles = styles.concat(result.newStyles);
        spans = result.spans;

        styles.push(StyleUtils.defaultStyle);
    }

    public inline function getSpanByIndex(index:Int):Span return spans[index];
    public inline function getStyleByName(name:String):Style return stylesByName[name];
    public inline function removeAllGlyphs():Void  for (span in spans) span.removeAllGlyphs();
    public inline function updateSpans(delta:Float):Void for (span in spans) span.update(delta);
}
