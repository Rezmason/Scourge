package net.rezmason.scourge.textview.ui;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.*;
import net.rezmason.scourge.textview.text.ParagraphAlign;
import net.rezmason.scourge.textview.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;
import net.rezmason.utils.Zig;
import net.rezmason.utils.display.FlatFont;

using net.rezmason.scourge.textview.core.GlyphUtils;

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

    public function stylePage(startIndex:Int, glyphs:Array<Glyph>, caretGlyph:Glyph, font:FlatFont):Int {
        var id:Int = 0;
        var pageSegment:Array<String> = page.slice(startIndex, startIndex + numRows);
        var spanIndex:Int = lineStyleIndices[startIndex];

        compositeDoc.removeAllGlyphs();
        styleCaret(caretGlyph, font);

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
                        var glyph:Glyph = glyphs[id];
                        if (charCode == Strings.HARD_SPACE_CODE) charCode = Strings.SPACE_CODE;
                        glyph.set_char(charCode, font);
                        currentSpan.addGlyph(glyph);
                        glyph.set_z(0);
                        id++;
                }
            }
        }

        updateSpans(0);

        return caretGlyphID;
    }

    public function updateDirtyText(bodyPaint:Int, force:Null<Bool> = false):Void {
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
                    page[ike] = padLineWithParagraph(line, compositeDoc.getParagraphByIndex(lineParagraphIndex));
                }
            }
        }
    }

    public function updateSpans(delta:Float):Void compositeDoc.updateSpans(delta);

    public function setText(text:String):Void {
        mainText = text;
        isDirty = true;
    }

    public function styleCaret(caretGlyph:Glyph, font:FlatFont):Void {}

    function combineDocs():Void {
        compositeDoc.setText(swapTabsWithSpaces(mainText));
    }

    inline function padLineWithParagraph(line:String, paragraph:Paragraph):String {
        var count:Int = 0;

        function check(char:Int):Void {
           if (char == STYLE_CODE || char == CARET_CODE || char == PARAGRAPH_STYLE_CODE) count++;
        }

        Utf8.iter(line, check);

        // Pads a string until its length, ignoring sigils, is numCols

        switch (paragraph.style.align) {
            case ALIGN_LEFT: line = rpad(line, ' ', numCols + count);
            case ALIGN_RIGHT: line = lpad(line, ' ', numCols + count);
            case ALIGN_CENTER: line = cpad(line, ' ', numCols + count);
            case ALIGN_JUSTIFY(secondaryAlign): 
                var secondary = rpad;
                switch (secondaryAlign) {
                    case ALIGN_RIGHT: secondary = lpad;
                    case ALIGN_CENTER: secondary = cpad;
                    case _:
                }
                line = jpad(line, ' ', numCols + count, secondary);
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
            case MOUSE(type, x, y) if (id != 0):
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
