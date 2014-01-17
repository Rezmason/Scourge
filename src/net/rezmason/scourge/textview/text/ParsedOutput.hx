package net.rezmason.scourge.textview.text;

typedef ParsedOutput = {
    var input:String;
    var output:String;
    var spans:Array<Span>;
    var interactiveSpans:Array<Span>;
    var styles:Map<String, Style>;
    var recycledSpans:Array<Span>;
}
