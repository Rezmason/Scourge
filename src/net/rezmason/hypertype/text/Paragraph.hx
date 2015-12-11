package net.rezmason.hypertype.text;

@:allow(net.rezmason.hypertype.text)
class Paragraph {

    public var style(default, null):ParagraphStyle;
    public var id(default, null):String;

    public function new():Void {
        reset();
    }

    public function reset():Void {
        style = null;
    }

    public function init(style:ParagraphStyle, id:String):Void {
        this.style = style;
        this.id = id;
    }

    public inline function copyTo(otherParagraph:Paragraph):Paragraph {
        if (otherParagraph == null) otherParagraph = new Paragraph();
        otherParagraph.init(style, id);
        return otherParagraph;
    }
}
