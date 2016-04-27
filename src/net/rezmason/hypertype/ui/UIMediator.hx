package net.rezmason.hypertype.ui;

import haxe.Utf8;

import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.core.MouseInteractionType;
import net.rezmason.hypertype.text.*;
import net.rezmason.hypertype.text.ParagraphAlign;
import net.rezmason.hypertype.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;
import net.rezmason.utils.Zig;

using net.rezmason.hypertype.core.GlyphUtils;

class UIMediator {

    inline static var LINE_TOKEN:String = '¬¬¬';

    public var isDirty(default, null):Bool;
    public var mouseSignal(default, null):Zig<String->MouseInteractionType->Void>;

    public var numRows(default, null):Int;
    public var numCols(default, null):Int;

    var logDoc:Document;
    var compositeDoc:Document;

    var pageLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var mainText:String;
    
    public function new():Void {
        mainText = '';
        logDoc = new Document();
        compositeDoc = new Document();
        compositeDoc.shareWith(logDoc);
        numRows = 0;
        numCols = 0;
        isDirty = false;
        mouseSignal = new Zig();
    }

    public function adjustLayout(numRows:Int, numCols:Int):Void {
        this.numRows = numRows;
        this.numCols = numCols;
        this.isDirty = true;
    }

    public function stylePage(startIndex:Int, body:Body, caretGlyph:Glyph):Int {
        var id:Int = 0;
        var pageSegment:Array<String> = page.slice(startIndex, startIndex + numRows);
        var spanIndex:Int = lineStyleIndices[startIndex];

        compositeDoc.removeAllGlyphs();
        styleCaret(caretGlyph);

        var currentSpan:Span = compositeDoc.getSpanByIndex(spanIndex);

        var caretGlyphID:Int = -1;

        for (line in pageSegment) {
            var index:Int = 0;

            for (index in 0...length(line)) {
                var charCode:Int = Utf8.charCodeAt(line, index);
                switch (charCode) {
                    case STYLE_CODE:
                        spanIndex++;
                        currentSpan = compositeDoc.getSpanByIndex(spanIndex);
                    case CARET_CODE:
                        caretGlyphID = id;
                    case PARAGRAPH_STYLE_CODE:
                        // nada
                    case _:
                        var glyph:Glyph = body.getGlyphByID(id);
                        if (charCode == Strings.HARD_SPACE_CODE) charCode = Strings.SPACE_CODE;
                        glyph.set_char(charCode);
                        currentSpan.addGlyph(glyph);
                        glyph.set_z(0);
                        id++;
                }
            }
        }

        updateSpans(0, true);

        return caretGlyphID;
    }

    public function updateDirtyText(force:Null<Bool> = false):Void {
        isDirty = isDirty || force;

        if (isDirty) {

            isDirty = false;

            if (numRows * numCols > 0) {

                // Simplify the combined text and wrap it to new lines as we construct the page

                combineDocs();
                page = compositeDoc.output.split('\n').map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

                // Add blank lines to the end, to reach the minimum page length (numRows)

                var blankLine:String = rpad('', ' ', numCols);
                pageLength = page.length;
                while (page.length < numRows) page.push(blankLine);

                // Count the sigils in each line, for style lookup

                var lineStyleIndex:Int = 0;
                lineStyleIndices = [lineStyleIndex];
                var lineParagraphIndex:Int = 0;
                for (ike in 0...page.length) {
                    var line = page[ike];
                    lineStyleIndex += line.split(STYLE).length - 1;
                    lineStyleIndices.push(lineStyleIndex);

                    lineParagraphIndex += line.split(PARAGRAPH_STYLE).length - 1;
                    var isFinal:Bool = ike == page.length - 1 || lengthWithoutSigils(page[ike + 1]) == 0;
                    page[ike] = padLineWithParagraph(line, compositeDoc.getParagraphByIndex(lineParagraphIndex), isFinal);
                }
            }
        }
    }

    public function updateSpans(delta:Float, force:Bool):Void compositeDoc.updateSpans(delta, force);

    public function setText(text:String):Void {
        mainText = text;
        isDirty = true;
    }

    public function styleCaret(caretGlyph:Glyph):Void {}

    function combineDocs():Void {
        compositeDoc.setText(swapTabsWithSpaces(mainText));
    }

    inline function lengthWithoutSigils(line:String):Int {
        var count:Int = 0;
        function check(char:Int):Void {
           if (char == STYLE_CODE || char == CARET_CODE || char == PARAGRAPH_STYLE_CODE) count++;
        }
        Utf8.iter(line, check);
        return length(line) - count;
    }

    inline function padLineWithParagraph(line:String, paragraph:Paragraph, isFinal:Bool):String {

        var numSigils:Int = length(line) - lengthWithoutSigils(line);
        // Pads a string until its length, ignoring sigils, is numCols

        switch (paragraph.style.align) {
            case LEFT: line = rpad(line, ' ', numCols + numSigils);
            case RIGHT: line = lpad(line, ' ', numCols + numSigils);
            case CENTER: line = cpad(line, ' ', numCols + numSigils);
            case JUSTIFY(secondaryAlign): 
                if (isFinal) {
                    var secondary = rpad;
                    switch (secondaryAlign) {
                        case RIGHT: secondary = lpad;
                        case CENTER: secondary = cpad;
                        case _:
                    }
                    line = secondary(line, ' ', numCols + numSigils);
                } else {
                    line = jpad(line, ' ', numCols + numSigils);
                }
        }

        return line;
    }

    inline function wrapLines(s:String):String {

        // Splits a line into an array of lines whose length, ignoring sigils, is numCols

        var charCodes:Array<Int> = [];
        Utf8.iter(s, function(c) charCodes.push(c));

        var wrappedLines:Array<String> = [];
        var index:Int = 0;
        var lastIndex:Int = 0;
        var count:Int = 0;
        var lastSpaceIndex:Int = -1;
        var countFromLastSpaceIndex:Int = 0;
        var len:Int = charCodes.length;
        
        while (index < len) {
            var char:Int = charCodes[index];
            if (char != STYLE_CODE && char != CARET_CODE && char != PARAGRAPH_STYLE_CODE) {
                count++;
                countFromLastSpaceIndex++;
                if (char == Strings.SPACE_CODE) {
                    lastSpaceIndex = index + 1;
                    countFromLastSpaceIndex = 0;
                }
                if (count > numCols) {
                    if (lastSpaceIndex != -1 && countFromLastSpaceIndex > 0) {
                        wrappedLines.push(sub(s, lastIndex, lastSpaceIndex - lastIndex));
                        lastIndex = lastSpaceIndex;
                        count = countFromLastSpaceIndex;
                        lastSpaceIndex = -1;
                    } else {
                        wrappedLines.push(sub(s, lastIndex, index - lastIndex));
                        lastIndex = index;
                        count = 1;
                    }
                }
            }
            index++;
        }

        if (wrappedLines.length == 0 || count > 0) {
            wrappedLines.push(sub(s, lastIndex, index - lastIndex));
        }

        return wrappedLines.join(LINE_TOKEN);
    }

    public function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y) if (id > 0):
                var targetSpan:Span = compositeDoc.getSpanByMouseID(id);
                if (targetSpan != null) handleSpanMouseInteraction(targetSpan, type);
            case _:
        }
    }

    function handleSpanMouseInteraction(span:Span, type:MouseInteractionType):Void {
        span.receiveInteraction(type);
        mouseSignal.dispatch(span.id, type);
    }

    inline function swapTabsWithSpaces(input:String):String {
        var left:String = '';
        var right:String = input;

        while (length(right) > 0) {
            var tabIndex:Int = right.indexOf('\t');
            if (tabIndex == -1) {
                left = left + right;
                right = '';
            } else {
                left = left + right.substr(0, tabIndex) + '     ';
                right = right.substr(tabIndex, right.length);
                right = sub(right, 1);
            }
        }

        return left;
    }

    inline function numScrollPositions():Int {
        return pageLength < (numRows - 1) ? 1 : pageLength - (numRows - 1) + 1;
    }

    public inline function bottomPos():Float return numScrollPositions() - 1;
}
