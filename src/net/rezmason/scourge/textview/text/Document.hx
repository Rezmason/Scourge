package net.rezmason.scourge.textview.text;

import net.rezmason.utils.Utf8Utils.*;

abstract Document(ParsedOutput) {

    public var input(get, never):String;
    public var output(get, never):String;

    public inline function new():Void clear();
    public inline function clear():Void this = Parser.makeEmptyOutput();
    public inline function loadStyles(input:String):Void {
        Parser.parse(input, this.styles, this.paragraphStyles, 0);
    }
    public inline function getSpanByIndex(index:Int):Span return this.spans[index];
    public inline function getParagraphByIndex(index:Int):Paragraph return this.paragraphs[index];
    public inline function getSpanByMouseID(id:Int):Span return this.interactiveSpans[id];
    public inline function getStyleByName(name:String):Style return this.styles[name];
    public inline function removeAllGlyphs():Void  for (span in this.spans) span.removeAllGlyphs();

    public inline function updateSpans(delta:Float, force:Bool):Void {
        for (key in this.spansByStyleName.keys()) this.styles[key].update(this.spansByStyleName[key], delta, force);
    }

    public inline function shareWith(otherDoc:Document):Void {
        var that:ParsedOutput = otherDoc.guts();

        // share styles
        if (this.styles != that.styles) {
            for (style in this.styles) if (that.styles[style.name] == null) that.styles[style.name] = style;
            this.styles = that.styles;
        }

        // share paragraph styles
        if (this.paragraphStyles != that.paragraphStyles) {
            for (paragraphStyle in this.paragraphStyles) {
                if (that.paragraphStyles[paragraphStyle.name] == null) {
                    that.paragraphStyles[paragraphStyle.name] = paragraphStyle;
                }
            }
            this.paragraphStyles = that.paragraphStyles;
        }

        // share recycled spans
        if (this.recycledSpans != that.recycledSpans) {
            for (span in this.recycledSpans) that.recycledSpans.push(span);
            this.recycledSpans = that.recycledSpans;
        }

        // share recycled paragraphs
        if (this.recycledParagraphs != that.recycledParagraphs) {
            for (paragraph in this.recycledParagraphs) that.recycledParagraphs.push(paragraph);
            this.recycledParagraphs = that.recycledParagraphs;
        }
    }

    public inline function append(otherDoc:Document):Void {

        shareWith(otherDoc);

        var that:ParsedOutput = otherDoc.guts();

        this.input += that.input;

        var thisIsEmpty:Bool = this.output == '§';

        if (thisIsEmpty) this.output = that.output;
        else this.output += that.output;

        for (style in this.styles) {
            if (this.spansByStyleName[style.name] == null) this.spansByStyleName[style.name] = [];
        }

        var spans:Array<Span> = [];
        var interactiveSpans:Array<Span> = [];
        for (span in that.spans) {
            var copy:Span = span.copyTo(this.recycledSpans.pop());
            if (copy.style.isInteractive) interactiveSpans.push(copy);
            this.spansByStyleName[copy.style.name].push(copy);
            spans.push(copy);
        }
        spans.shift();
        for (ike in 0...interactiveSpans.length) interactiveSpans[ike].setMouseID(this.interactiveSpans.length + ike);

        var paragraphs:Array<Paragraph> = [];
        for (paragraph in that.paragraphs) {
            var copy:Paragraph = paragraph.copyTo(this.recycledParagraphs.pop());
            paragraphs.push(copy);
        }
        paragraphs.shift();

        this.spans = this.spans.concat(spans);
        this.interactiveSpans = this.interactiveSpans.concat(interactiveSpans);
        this.paragraphs = this.paragraphs.concat(paragraphs);
    }

    public inline function setText(input:String):Void {
        for (span in this.spans) this.recycledSpans.push(span);
        for (paragraph in this.paragraphs) this.recycledParagraphs.push(paragraph);
        this = Parser.parse(input, this.styles, this.paragraphStyles, 0, this.recycledSpans, this.recycledParagraphs);
    }

    inline function guts():ParsedOutput return this;

    public inline function spanStyleNames():Array<String> {
        return this.spans.map(function (sp) return '${sp.style.name}' );
    }

    public inline function removeInteraction():Void {
        for (span in this.interactiveSpans) if (span != null) span.setInteractive(false);
    }

    inline function get_input():String return this.input;
    inline function get_output():String return this.output;
}
