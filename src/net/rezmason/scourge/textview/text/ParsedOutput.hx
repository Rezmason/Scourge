package net.rezmason.scourge.textview.text;

typedef ParsedOutput = {
    var input:String;
    var output:String;
    var spans:Array<Span>;
    var interactiveSpans:Array<Span>;
    var paragraphs:Array<Paragraph>;
    var styles:Map<String, Style>;
    var paragraphStyles:Map<String, ParagraphStyle>;
    var recycledSpans:Array<Span>;
    var recycledParagraphs:Array<Paragraph>;
    var spansByStyleName:Map<String, Array<Span>>;
}
