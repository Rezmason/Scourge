package net.rezmason.scourge.textview.text;

class TextRegion {

    var stylesByIndex:Array<Style>;
    var styles:StyleSet;

    public function new(styles:StyleSet = null):Void {
        this.styles = styles;
        if (this.styles == null) this.styles = new StyleSet();
    }

    public inline function getStyleByIndex(index:Int):Style {
        return stylesByIndex[index] != null ? stylesByIndex[index] : styles.defaultStyle;
    }

    public inline function extractFromText(input:String, refreshStyles:Bool = false):String {
        stylesByIndex = [];
        return styles.extract(input, stylesByIndex, refreshStyles);
    }
}
