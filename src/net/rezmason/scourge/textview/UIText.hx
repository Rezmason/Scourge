package net.rezmason.scourge.textview;

import flash.ui.Keyboard;

import msignal.Signal;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.text.AnimatedStyle;
import net.rezmason.scourge.textview.text.Sigil.STYLE;
import net.rezmason.scourge.textview.text.Sigil.STYLE_CODE;
import net.rezmason.scourge.textview.text.Style;
import net.rezmason.scourge.textview.text.StyleSet;
import net.rezmason.utils.FlatFont;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef FrozenInteraction = {
    var id:Int;
    var interaction:Interaction;
}

class UIText {

    public var hintSignal(default, null):Signal2<Array<TextToken>, {t:Int, c:Int}>;
    public var execSignal(default, null):Signal1<Array<TextToken>>;

    public var frozen(get, set):Bool;

    var numRows:Int;
    var numCols:Int;

    inline static var LINE_TOKEN:String = '¬¬¬';

    var stylesByIndex:Array<Style>;
    var styles:StyleSet;

    var combinedText:String;
    var combinedTextLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var blurb:String;
    var prompt:String;
    var caretStart:String;
    var caretEnd:String;
    var caretIndex:Int;
    var tokenIndex:Int;
    var inputString:String;
    var outputString:String;
    var textIsDirty:Bool;
    var caretStyle:AnimatedStyle;
    var inputTokens:Array<TextToken>;
    var outputTokens:Array<TextToken>;

    var inputHistory:Array<Array<TextToken>>;
    var histItr:Int;

    var currentPlayerName:String;
    var currentPlayerColor:Int;

    var frozenQueue:List<FrozenInteraction>;
    var _frozen:Bool;

    public function new():Void {

        styles = new StyleSet();

        numRows = 0;
        numCols = 0;

        blurb = '';

        styles.extract(Strings.BREATHING_PROMPT_STYLE);
        styles.extract(Strings.CARET_STYLE);
        styles.extract(Strings.INPUT_STYLE);

        setPlayer('rezmason', 0xFF3030);

        caretStyle = cast styles.getStyleByName('caret');
        caretStart = '§{caret}';
        caretEnd = '§{}';

        caretIndex = 0;
        tokenIndex = 0;

        inputString = '';
        outputString = '\n';
        textIsDirty = false;

        inputTokens = [];
        inputHistory = [];
        histItr = 1;

        hintSignal = new Signal2();
        execSignal = new Signal1();

        frozenQueue = new List();

        updateDirtyText(true);
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
            for (index in 0...Utf8.length(line)) {
                var charCode:Int = Utf8.charCodeAt(line, index);
                if (charCode == STYLE_CODE) {
                    currentStyle = getStyleByIndex(++styleIndex);
                } else {
                    // this is why setScrollPos is in UIBody
                    // It could be passed in
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(charCode, font);
                    currentStyle.addGlyph(glyph);
                    glyph.set_z(0);
                    //
                }
            }
        }

        updateStyledGlyphs(0);
    }

    public function updateDirtyText(force:Bool = false):Bool {

        var updating:Bool = force || textIsDirty;

        if (updating) {

            if (!force) textIsDirty = false;

            /*
            var left:String = sub(inputString, 0, caretIndex);
            var mid:String = sub(inputString, caretIndex, 1);
            var right:String = sub(inputString, caretIndex + 1);

            if (mid == '') mid = ' ';

            if (mid == ' ') caretStyle.start();
            else caretStyle.stop();
            */

            combinedText = blurb + outputString + prompt + inputString/*left + caretStart + mid + caretEnd + right*/;
            combinedText = swapTabsWithSpaces(combinedText);

            if (numRows * numCols > 0) {

                // Simplify the combinedText and wrap it to new lines as we construct the page

                page = extractFromText(combinedText, false).split('\n').map(wrapLines).join(LINE_TOKEN).split(LINE_TOKEN);

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
        }

        return updating;
    }

    public function resetStyledGlyphs():Void styles.removeAllGlyphs();

    public function updateStyledGlyphs(delta:Float):Void styles.updateGlyphs(delta);

    public function setText(text:String):Void blurb = text;

    public function setPlayer(name:String, color:Int):Void {
        currentPlayerName = name;
        currentPlayerColor = color;

        var r:Float = (color >> 16 & 0xFF) / 0xFF;
        var g:Float = (color >> 8  & 0xFF) / 0xFF;
        var b:Float = (color >> 0  & 0xFF) / 0xFF;

        prompt =
        '∂{name:promptHead, basis:breathingprompt, r:$r, g:$g, b:$b}Ω' +
        '§{name:prompt, r:$r, g:$g, b:$b} $currentPlayerName§{} => §{}';
    }

    inline function padLine(line:String):String {

        var count:Int = 0;
        var right:String = line;
        while (length(right) > 0) {
            var sigilIndex:Int = right.indexOf(STYLE);
            if (sigilIndex == -1) break;
            right = sub(right, sigilIndex + 1);
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

        if (frozen) frozenQueue.add({id:id, interaction:interaction});

        switch (interaction) {
            case KEYBOARD(type, key, char, shift, alt, ctrl) if (type == KEY_DOWN || type == KEY_REPEAT):
                switch (key) {
                    case Keyboard.BACKSPACE: handleBackspace(alt, ctrl);
                    case Keyboard.ENTER: handleEnter();
                    case Keyboard.ESCAPE: handleEscape();
                    case Keyboard.LEFT: handleLeft(alt, ctrl);
                    case Keyboard.RIGHT: handleRight(alt, ctrl);
                    case Keyboard.UP: handleUp();
                    case Keyboard.DOWN: handleDown();
                    case Keyboard.TAB: handleTab();
                    case _: handleChar(char);
                }
            case MOUSE(type, x, y) if (id != 0):
                var targetStyle:Style = styles.getStyleByMouseID(id);
                if (targetStyle != null) {
                    targetStyle.interact(type);
                    if (type == CLICK) trace('${targetStyle.name} clicked!');
                }
            case _:
        }
    }

    public function receiveHint(input:Array<TextToken>, tokenIndex:Int, caretIndex:Int, output:Array<TextToken>):Void {
        /*
        if (input != null) this.inputTokens = input;
        this.outputTokens = output;
        */
        trace("HINT");
        trace(input);
        trace('$tokenIndex $caretIndex');
        trace(output);
    }

    public function receiveExec(input:Array<TextToken>, output:Array<TextToken>):Void {
        trace("EXEC");
        trace(input);
        trace(output);
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {

        // Only erases text; doesn't erase empty tokens

        /*
        var left:String = sub(inputString, 0, caretIndex);
        var right:String = sub(inputString, caretIndex);

        if (length(left) > 0) {
            var lim:Int = -1;

            if (ctrl) lim = 0;
            // TODO: alt-delete
            else lim = length(left) - 1;

            if (lim == -1) lim = 0;

            left = sub(left, 0, lim);
            caretIndex = lim;
        }

        inputString = left + right;
        textIsDirty = true;
        */
    }

    inline function handleEnter():Void {
        blurb += outputString + prompt + inputString;
        if (length(inputString) == 0) {
            outputString = '\n';
        } else {
            outputString = '\n' + inputString + '\n';
            execSignal.dispatch(inputTokens);
            inputHistory.push(inputTokens.copy());
            histItr = inputHistory.length;
        }
        inputTokens = [];
        // inputString = '';
        // caretIndex = 0;
        textIsDirty = true;
    }

    inline function handleTab():Void {
        if (length(inputString) > 0) {
            hintSignal.dispatch(inputTokens, {t:tokenIndex, c:caretIndex});
        }
    }

    inline function handleEscape():Void {
        if (length(inputString) > 0) {
            inputTokens = [];
            //inputString = '';
            // caretIndex = 0;
            textIsDirty = true;
        }
    }

    inline function handleLeft(alt:Bool, ctrl:Bool):Void {
        /*
        caretIndex--;
        if (caretIndex < 0) caretIndex = 0;
        textIsDirty = true;
        */
        // TODO: alt-left
        // TODO: ctrl-left
    }

    inline function handleRight(alt:Bool, ctrl:Bool):Void {
        /*
        caretIndex++;
        if (caretIndex > length(inputString)) caretIndex = length(inputString);
        textIsDirty = true;
        */
        // TODO: alt-right
        // TODO: ctrl-left
    }

    inline function handleUp():Void {
        if (inputHistory.length > 0) {
            if (histItr > 0) histItr--;
            inputTokens = inputHistory[histItr].copy();
            // inputString;
            // caretIndex = inputString.length;
            textIsDirty = true;
        }
    }

    inline function handleDown():Void {
        if (inputHistory.length > 0) {
            if (histItr < inputHistory.length) histItr++;
            if (histItr == inputHistory.length) inputTokens = [];
            else inputTokens = inputHistory[histItr].copy();
            // inputString;
            // caretIndex = inputString.length;
            textIsDirty = true;
        }
    }

    inline function handleChar(char:Int):Void {
        /*
        var left:String = sub(inputString, 0, caretIndex);
        var right:String = sub(inputString, caretIndex);

        if (char > 0) {
            left += String.fromCharCode(char);
            caretIndex++;
            inputString = left + right;
            textIsDirty = true;
        }
        */
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

    inline function rpad(input:String, pad:String, len:Int):String {
        len = len - length(input);
        var str:String = '';
        while (str.length < len) str = str + pad;
        return input + str;
    }

    inline function numScrollPositions():Int {
        return combinedTextLength < (numRows - 1) ? 1 : combinedTextLength - (numRows - 1) + 1;
    }

    public inline function bottomPos():Float return numScrollPositions() - 1;

    static inline function sub(input:String, pos:Int, len:Int = -1):String {

        var output:String = '';
        if (len == -1) len = length(input);
        if (input != '' && len > 0 && pos < length(input)) {
            output = Utf8.sub(input, pos, length(input));
            output = Utf8.sub(output, 0, len);
        }

        return output;
    }

    static inline function length(input:String):Int {
        var output:Int = 0;
        if (input != '') output = Utf8.length(input);
        return output;
    }

    inline function get_frozen():Bool return _frozen;

    inline function set_frozen(val:Bool):Bool {
        if (_frozen && !val) {
            _frozen = false;
            while (!frozenQueue.isEmpty()) {
                var leftovers:FrozenInteraction = frozenQueue.pop();
                interact(leftovers.id, leftovers.interaction);
            }
        }
        _frozen = val;
        return val;
    }

    inline function isTokenModifiable(token:TextToken):Bool {
        return switch (token) {
            case PLAIN_TEXT(text): true;
            case EMPTY_CAPSULE(type, caption): true;
            case INCOMPLETE_CAPSULE(type, valid): true;
            case _: false;
        }
    }
}
