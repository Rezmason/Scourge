package net.rezmason.scourge.textview.text;

abstract Document(ParsedOutput) {

    public function new():Void clear();
    public inline function clear():Void this = Parser.getEmptyOutput();

    public inline function setText(input:String, bodyPaint:Int):Void this = Parser.parse(input, this.styles, bodyPaint, this.recycledSpans.concat(this.spans));
    public inline function loadStyles(input:String):Void Parser.parse(input, this.styles, 0);
    public inline function getStyledText():String return this.output;
    public inline function getSpanByIndex(index:Int):Span return this.spans[index];
    public inline function getSpanByMouseID(id:Int):Span return this.interactiveSpans[id];
    public inline function getStyleByName(name:String):Style return this.styles[name];
    public inline function removeAllGlyphs():Void  for (span in this.spans) span.removeAllGlyphs();
    public inline function updateSpans(delta:Float):Void for (span in this.spans) span.update(delta);

    public inline function appendText(input:String, bodyPaint):Void {
        var that:ParsedOutput = Parser.parse(input, this.styles, bodyPaint, this.recycledSpans);
        this.input = this.input + that.input;
        this.output = this.output + that.output;
        this.spans = this.spans.concat(that.spans);
        that.interactiveSpans.shift();
        this.interactiveSpans = this.interactiveSpans.concat(that.interactiveSpans);
    }
}
