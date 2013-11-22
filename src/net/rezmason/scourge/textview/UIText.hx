package net.rezmason.scourge.textview;

import haxe.Utf8;

import msignal.Signal;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.text.Sigil.STYLE;
import net.rezmason.scourge.textview.text.Sigil.STYLE_CODE;
import net.rezmason.scourge.textview.text.Style;
import net.rezmason.scourge.textview.text.StyleSet;
import net.rezmason.utils.FlatFont;
import net.rezmason.utils.Utf8Utils.*;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIText {

    inline static var LINE_TOKEN:String = '¬¬¬';

    public var clickSignal(default, null):Signal1<String>;

    var numRows:Int;
    var numCols:Int;

    var stylesByIndex:Array<Style>;
    var styles:StyleSet;

    var pageLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var mainText:String;
    var styleEnd:String;
    var textIsDirty:Bool;

    var padLineSigilCount:Int;

    public function new():Void {
        styles = new StyleSet();
        numRows = 0;
        numCols = 0;
        mainText = '';
        styleEnd = '§{}';
        textIsDirty = false;
        clickSignal = new Signal1();
    }

    public inline function getStyleByIndex(index:Int):Style {
        return stylesByIndex[index] != null ? stylesByIndex[index] : styles.defaultStyle;
    }

    inline function extractFromText(input:String, refreshStyles:Bool = false):String {
        stylesByIndex = [];
        return styles.extract(input, stylesByIndex, refreshStyles);
    }

    public function adjustLayout(numRows:Int, numCols:Int):Void {
        this.numRows = numRows;
        this.numCols = numCols;
        this.textIsDirty = true;
    }

    public function stylePage(startIndex:Int, glyphs:Array<Glyph>, font:FlatFont):Void {
        var id:Int = 0;
        var pageSegment:Array<String> = getPageSegment(startIndex);
        var styleIndex:Int = getLineStyleIndex(startIndex);

        resetStyledGlyphs();

        var currentStyle:Style = getStyleByIndex(styleIndex);

        for (line in pageSegment) {
            var index:Int = 0;

            for (index in 0...length(line)) {
                var charCode:Int = Utf8.charCodeAt(line, index);
                if (charCode == STYLE_CODE) {
                    currentStyle = getStyleByIndex(++styleIndex);
                } else {
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(charCode, font);
                    currentStyle.addGlyph(glyph);
                    glyph.set_z(0);
                }
            }
        }

        updateStyledGlyphs(0);
    }

    public function updateDirtyText(force:Bool = false):Bool {

        var updating:Bool = force || textIsDirty;

        if (updating) {

            if (!force) textIsDirty = false;

            if (numRows * numCols > 0) {

                // Simplify the combined text and wrap it to new lines as we construct the page

                page = extractFromText(swapTabsWithSpaces(combineText()), false).split('\n').map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

                // Add blank lines to the end, to reach the minimum page length (numRows)

                var blankParagraph:String = rpad('', ' ', numCols);
                pageLength = page.length;
                while (page.length < numRows) page.push(blankParagraph);

                // Count the sigils in each line, for style lookup

                var lineStyleIndex:Int = 0;
                lineStyleIndices = [lineStyleIndex];
                for (line in page) {
                    lineStyleIndex += line.split(STYLE).length - 1;
                    lineStyleIndices.push(lineStyleIndex);
                }
            }
        }

        return updating;
    }

    public function resetStyledGlyphs():Void styles.removeAllGlyphs();

    public function updateStyledGlyphs(delta:Float):Void styles.updateGlyphs(delta);

    public function setText(text:String):Void {
        mainText = text;
        textIsDirty = true;
    }

    function combineText():String return mainText;

    inline function padLine(line:String):String {
        padLineSigilCount = 0;
        Utf8.iter(line, checkForSigil);

        // Pads a string until its length, ignoring sigils, is numCols
        return rpad(line, ' ', numCols + padLineSigilCount);
    }

    inline function checkForSigil(char:Int):Void if (char == STYLE_CODE) padLineSigilCount++;

    inline function wrapLines(s:String) {

        // Splits a line into an array of lines whose length, ignoring sigils, is numCols

        var left:String = '';
        var right:String = s;

        var wrappedLines:Array<String> = [];

        var count:Int = 0;
        while (right.length > 0) {
            var len:Int = right.length;
            var line:String = '';
            line = sub(right, 0, numCols - count);
            var sigilIndex:Int = line.indexOf(STYLE);
            if (sigilIndex == -1) {
                left = left + line;
                wrappedLines.push(padLine(left));
                left = '';
                if (numCols - count < right.length) {
                    right = sub(right, numCols - count);
                    left = '';
                } else {
                    right = '';
                    left = null;
                }
                count = 0;
            } else {
                line = right.substr(0, sigilIndex);
                if (sigilIndex > 0) left = left + line;
                left = left + STYLE;
                right = right.substr(sigilIndex, right.length);
                if (length(right) > 1) right = sub(right, 1);
                else right = '';
                count += length(line);
            }
        }

        if (left != null) wrappedLines.push(padLine(left));

        return wrappedLines.join(LINE_TOKEN);
    }

    public function interact(id:Int, interaction:Interaction):Void {

        switch (interaction) {
            case MOUSE(type, x, y) if (id != 0):
                var targetStyle:Style = styles.getStyleByMouseID(id);
                if (targetStyle != null) {
                    targetStyle.interact(type);
                    if (type == CLICK) clickSignal.dispatch(targetStyle.name);
                }
            case _:
        }
    }

    public function getPageSegment(index:Int):Array<String> return page.slice(index, index + numRows);

    public function getLineStyleIndex(index:Int):Int return lineStyleIndices[index];

    inline function swapTabsWithSpaces(input:String):String {
        var left:String = '';
        var right:String = input;

        while (length(right) > 0) {
            var tabIndex:Int = right.indexOf('\t');
            if (tabIndex == -1) {
                left = left + right;
                right = '';
            } else {
                left = left + right.substr(0, tabIndex) + '    ';
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
