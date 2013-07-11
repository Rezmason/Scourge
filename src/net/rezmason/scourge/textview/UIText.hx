package net.rezmason.scourge.textview;

import flash.ui.Keyboard;

import haxe.Utf8;
import openfl.Assets;

import net.rezmason.scourge.textview.TestStrings;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.AnimatedStyle;
import net.rezmason.scourge.textview.text.Sigil.STYLE;
import net.rezmason.scourge.textview.text.Style;
import net.rezmason.scourge.textview.text.StyleSet;

@:allow(net.rezmason.scourge.textview.UIBody)
class UIText {

    var numRows:Int;
    var numCols:Int;
    var numRowsForLayout:Int;

    inline static var LINE_TOKEN:String = '¬¬¬';

    var stylesByIndex:Array<Style>;
    var styles:StyleSet;

    var combinedText:String;
    var combinedTextLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var blurb:String;
    var prompt:String;
    var caret:String;
    var systemInput:String;
    var systemOutput:String;
    var textIsDirty:Bool;
    var caretStyle:AnimatedStyle;
    var interpret:String->String;

    public function new(interpret:String->String):Void {

        this.interpret = interpret;

        styles = new StyleSet();

        numRows = 0;
        numCols = 0;
        numRowsForLayout = 0;

        // blurb = [TestStrings.SYMBOLS + " " + TestStrings.WEIRD_SYMBOLS, TestStrings.SPLASH, TestStrings.BOARD].join("\n\n");
        // blurb = Assets.getText("assets/not plus.txt");
        // blurb = Assets.getText("assets/enterprise.txt");
        // blurb = Assets.getText("assets/acid2.txt");
        blurb = TestStrings.STYLED_TEXT;
        // blurb = "One. §{i:1}Two§{}.";

        styles.extract(TestStrings.BREATHING_PROMPT_STYLE);
        styles.extract(TestStrings.CARET_STYLE);

        caretStyle = cast styles.getStyleByName('caret');

        prompt = '§{breathingprompt}Ω_rezmason§{} => §{}';
        setCaret('|');
        systemInput = '';
        systemOutput = '\n';
        textIsDirty = false;

        updateDirtyText(true);
    }

    public inline function getStyleByIndex(index:Int):Style {
        return stylesByIndex[index] != null ? stylesByIndex[index] : styles.defaultStyle;
    }

    public inline function extractFromText(input:String, refreshStyles:Bool = false):String {
        stylesByIndex = [];
        return styles.extract(input, stylesByIndex, refreshStyles);
    }

    function adjustLayout(numRows:Int, numCols:Int, numRowsForLayout:Int):Void {
        this.numRows = numRows;
        this.numCols = numCols;
        this.numRowsForLayout = numRowsForLayout;
        this.textIsDirty = true;
    }

    function updateDirtyText(force:Bool = false):Bool {

        var updating:Bool = force || textIsDirty;

        if (updating) {
            if (!force) textIsDirty = false;

            combinedText = blurb + systemOutput + prompt + systemInput + caret;
            if (combinedText == null) combinedText = '';
            this.combinedText = swapTabsWithSpaces(combinedText);

            if (numRows * numCols > 0) {

                // Simplify the combinedText and wrap it to new lines as we construct the page

                page = extractFromText(this.combinedText, false).split('\n').map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

                // Add blank lines to the end, to reach the minimum page length (numRows)

                var blankParagraph:String = rpad('', ' ', numCols);
                combinedTextLength = page.length;
                while (page.length < numRows) page.push(blankParagraph);

                // Count the sigils in each line, for style lookup

                var lineStyleIndex:Int = 0;
                lineStyleIndices = [lineStyleIndex];
                for (line in page) {
                    lineStyleIndex += line.split(STYLE).length - 1;
                    lineStyleIndices.push(lineStyleIndex);
                }
            }

            caretStyle.time = 0;
        }

        return updating;
    }

    function resetStyledGlyphs():Void styles.removeAllGlyphs();

    function updateStyledGlyphs(delta:Float):Void styles.updateGlyphs(delta);

    function setText(text:String):Void blurb = text;

    function setPrompt(text:String):Void prompt = text;

    function setCaret(text:String):Void caret = '§{caret}$text§{}';

    inline function padLine(line:String):String {

        var count:Int = 0;
        var right:String = line;
        while (Utf8.length(right) > 0) {
            var sigilIndex:Int = right.indexOf(STYLE);
            if (sigilIndex == -1) break;
            right = right.substr(sigilIndex, right.length);
            right = Utf8.sub(right, 1, Utf8.length(right));
            count++;
        }

        // Pads a string until its length, ignoring sigils, is numCols
        line = rpad(line, ' ', numCols + count);
        return line;
    }

    inline function wrapLines(s:String) {

        // Splits a line into an array of lines whose length, ignoring sigils, is numCols

        var left:String = '';
        var right:String = s;

        var wrappedLines:Array<String> = [];

        var count:Int = 0;
        while (right.length > 0) {
            var len:Int = right.length;
            var line:String = '';
            line = Utf8.sub(right, 0, numCols - count);
            var sigilIndex:Int = line.indexOf(STYLE);
            if (sigilIndex == -1) {
                left = left + line;
                wrappedLines.push(padLine(left));
                left = '';
                if (numCols - count < right.length) {
                    right = Utf8.sub(right, numCols - count, Utf8.length(right));
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
                if (Utf8.length(right) > 1) right = Utf8.sub(right, 1, Utf8.length(right));
                else right = '';
                count += Utf8.length(line);
            }
        }

        if (left != null) wrappedLines.push(padLine(left));

        return wrappedLines.join(LINE_TOKEN);
    }

    function interact(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case KEYBOARD(type, key, char, shift, alt, ctrl):
                if (type == KEY_DOWN || type == KEY_REPEAT) {
                    switch (key) {
                        case Keyboard.BACKSPACE:
                            // delete command
                            if (systemInput.length > 0) {
                                var lim:Int = -1;

                                if (ctrl) lim = 0;
                                else if (alt) lim = systemInput.lastIndexOf(' ');
                                else lim = systemInput.length - 1;

                                if (lim == -1) lim = 0;

                                systemInput = systemInput.substr(0, lim);
                            }
                            textIsDirty = true;
                        case Keyboard.ENTER:
                            blurb += systemOutput + prompt + systemInput;
                            if (systemInput.length == 0) systemOutput = '\n';
                            else systemOutput = '\n' + interpret(systemInput) + '\n';
                            systemInput = '';
                            textIsDirty = true;
                        case Keyboard.ESCAPE:
                            if (systemInput.length > 0) {
                                textIsDirty = true;
                                systemInput = '';
                            }
                        case Keyboard.RIGHT:
                            if (type == KEY_DOWN) trace("Auto complete");
                        case _:
                            if (char > 0) {
                                systemInput += String.fromCharCode(char);
                                textIsDirty = true;
                            }
                    }
                }
                case MOUSE(type, x, y):
                    if (id != 0) {
                        var targetStyle:Style = styles.getStyleByMouseID(id);
                        if (targetStyle != null) {
                            targetStyle.interact(type);
                            if (type == CLICK) trace('${targetStyle.name} clicked!');
                        }
                    }
        }
    }

    function getPageSegment(index:Int):Array<String> return page.slice(index, index + numRows);

    function getLineStyleIndex(index:Int):Int return lineStyleIndices[index];

    inline function swapTabsWithSpaces(input:String):String {
        var left:String = '';
        var right:String = input;

        while (Utf8.length(right) > 0) {
            var tabIndex:Int = right.indexOf('\t');
            if (tabIndex == -1) {
                left = left + right;
                right = '';
            } else {
                left = left + right.substr(0, tabIndex) + '    ';
                right = right.substr(tabIndex, right.length);
                right = Utf8.sub(right, 1, Utf8.length(right));
            }
        }

        return left;
    }

    inline function rpad(input:String, pad:String, len:Int):String {
        len = len - Utf8.length(input);
        var str:String = '';
        while (str.length < len) str = str + pad;
        return input + str;
    }

    inline function numScrollPositions():Int {
        return combinedTextLength < numRowsForLayout ? 1 : combinedTextLength - numRowsForLayout + 1;
    }

    inline function bottomPos():Float return numScrollPositions() - 1;
}
