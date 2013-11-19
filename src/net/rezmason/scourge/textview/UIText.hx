package net.rezmason.scourge.textview;

import flash.ui.Keyboard;

import msignal.Signal;

import haxe.Utf8;

import net.rezmason.scourge.textview.TextToken;
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
    var waiting:Bool;

    var numRows:Int;
    var numCols:Int;

    inline static var LINE_TOKEN:String = '¬¬¬';

    var stylesByIndex:Array<Style>;
    var styles:StyleSet;

    var combinedText:String;
    var combinedTextLength:Int;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var mainText:String;
    var prompt:String;
    var caretStart:String;
    var styleEnd:String;
    var caretIndex:Int;
    var tokenIndex:Int;
    var outputString:String;
    var hintString:String;
    var textIsDirty:Bool;
    var caretStyle:AnimatedStyle;
    var inputTokens:Array<TextToken>;
    var outputTokens:Array<TextToken>;
    var hintTokens:Array<TextToken>;

    var inputHistory:Array<Array<TextToken>>;
    var histItr:Int;

    var currentPlayerName:String;
    var currentPlayerColor:Int;

    var frozenQueue:List<FrozenInteraction>;
    var _frozen:Bool;

    var padLineSigilCount:Int;

    public function new():Void {

        styles = new StyleSet();

        numRows = 0;
        numCols = 0;

        mainText = '';

        styles.extract(Strings.BREATHING_PROMPT_STYLE);
        styles.extract(Strings.CARET_STYLE);
        styles.extract(Strings.WAIT_STYLES);
        styles.extract(Strings.INPUT_STYLE);

        styleEnd = '§{}';

        setPlayer('rezmason', 0xFF3030);

        caretStyle = cast styles.getStyleByName('caret');
        caretStart = '§{caret}';

        caretIndex = 0;
        tokenIndex = 0;

        outputString = '';
        hintString = '';
        textIsDirty = false;

        outputTokens = [];
        hintTokens = [];

        inputTokens = [{text:'', type:PLAIN_TEXT, color:Colors.white()}];
        inputHistory = [];
        histItr = 1;

        hintSignal = new Signal2();
        execSignal = new Signal1();

        frozenQueue = new List();
        frozen = false;
        waiting = false;

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

            combinedText = mainText;
            if (length(mainText) > 0) combinedText += '\n';
            combinedText += outputString;

            if (waiting) {
                combinedText += Strings.WAIT_INDICATOR;
            } else {
                combinedText += prompt;
                for (ike in 0...inputTokens.length) {
                    var index:Int = ike == tokenIndex ? caretIndex : -1;
                    combinedText += stringifyToken(inputTokens[ike], index, false, true);
                }

                if (hintTokens.length > 0) {
                    combinedText += '\n\t';
                    for (token in hintTokens) combinedText += stringifyToken(token, -1, true, true);
                }

                combinedText = swapTabsWithSpaces(combinedText);
            }

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

    public function setText(text:String):Void {
        mainText = text;
        textIsDirty = true;
    }

    public function setPlayer(name:String, color:Int):Void {
        currentPlayerName = name;
        currentPlayerColor = color;

        var r:Float = (color >> 16 & 0xFF) / 0xFF;
        var g:Float = (color >> 8  & 0xFF) / 0xFF;
        var b:Float = (color >> 0  & 0xFF) / 0xFF;

        prompt =
        '∂{name:promptHead, basis:breathingprompt, r:$r, g:$g, b:$b}Ω' +
        '§{name:prompt, r:$r, g:$g, b:$b} $currentPlayerName§{}' + Strings.PROMPT + styleEnd;
    }

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

    public function receiveHint(input:Array<TextToken>, tokenIndex:Int, caretIndex:Int, hint:Array<TextToken>):Void {
        this.inputTokens = input;
        this.tokenIndex = tokenIndex;
        this.caretIndex = caretIndex;
        this.hintTokens = hint;
        textIsDirty = true;
    }

    public function receiveExec(output:Array<TextToken>, done:Bool):Void {
        if (done) {
            frozen = false;
            waiting = false;
        }

        this.outputTokens = output;
        outputString = '';
        for (token in outputTokens) outputString += stringifyToken(token, -1, false, true);
        outputString += '\n';
        textIsDirty = true;
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        var left:String = sub(inputTokens[tokenIndex].text, 0, caretIndex);
        var right:String = sub(inputTokens[tokenIndex].text, caretIndex);

        if (length(left) > 0) {
            var lim:Int = -1;

            if (ctrl) lim = 0;
            // TODO: alt-delete
            else lim = length(left) - 1;

            if (lim == -1) lim = 0;

            left = sub(left, 0, lim);
            caretIndex = lim;
        }

        inputTokens[tokenIndex].text = left + right;
        refreshHint();
        textIsDirty = true;
    }

    inline function handleEnter():Void {
        var inputString:String = '';
        for (token in inputTokens) inputString += stringifyToken(token, -1, false, false);

        var isEmpty:Bool = inputTokens.length == 1 && length(inputTokens[0].text) == 0;

        var oldOutputString:String = '';
        for (token in outputTokens) oldOutputString += stringifyToken(token, -1, false, false);
        if (length(oldOutputString) > 0) oldOutputString += '\n';

        if (length(mainText) > 0) mainText += '\n';
        mainText += oldOutputString + prompt + inputString;
        if (!isEmpty) {
            execSignal.dispatch(inputTokens);
            frozen = true;
            waiting = true;
            inputHistory.push(inputTokens.copy());
            histItr = inputHistory.length;
        }
        inputTokens = [{text:'', type:PLAIN_TEXT, color:Colors.white()}];
        hintTokens = [];
        outputTokens = [];
        outputString = '';
        caretIndex = 0;
        tokenIndex = 0;
        textIsDirty = true;
    }

    inline function handleTab():Void {

    }

    inline function handleEscape():Void {
        inputTokens = [{text:'', type:PLAIN_TEXT, color:Colors.white()}];
        caretIndex = 0;
        tokenIndex = 0;
        refreshHint();
        textIsDirty = true;
    }

    inline function handleLeft(alt:Bool, ctrl:Bool):Void {
        caretIndex--;
        if (caretIndex < 0) {
            if (!prevToken()) caretIndex = 0;
        }
        refreshHint();
        textIsDirty = true;
        // TODO: alt-left
        // TODO: ctrl-left
    }

    inline function handleRight(alt:Bool, ctrl:Bool):Void {
        caretIndex++;
        var len:Int = length(inputTokens[tokenIndex].text);
        if (caretIndex > len) {
            if (!nextToken()) caretIndex = len;
        }
        refreshHint();
        textIsDirty = true;
        // TODO: alt-right
        // TODO: ctrl-left
    }

    inline function prevToken():Bool {
        var feasible:Bool = tokenIndex > 0;
        if (feasible) {
            tokenIndex--;
            caretIndex = length(inputTokens[tokenIndex].text);
        }
        return feasible;
    }

    inline function nextToken():Bool {
        var feasible:Bool = tokenIndex < inputTokens.length - 1;
        if (feasible) {
            tokenIndex++;
            caretIndex = 0;
        }
        return feasible;
    }

    inline function handleUp():Void {
        if (inputHistory.length > 0) {
            if (histItr > 0) histItr--;
            inputTokens = inputHistory[histItr].copy();
            tokenIndex = inputTokens.length - 1;
            caretIndex = length(inputTokens[tokenIndex].text);
            refreshHint();
            textIsDirty = true;
        }
    }

    inline function handleDown():Void {
        if (inputHistory.length > 0) {
            if (histItr < inputHistory.length) histItr++;
            if (histItr == inputHistory.length) inputTokens = [{text:'', type:PLAIN_TEXT, color:Colors.white()}];
            else inputTokens = inputHistory[histItr].copy();
            tokenIndex = inputTokens.length - 1;
            caretIndex = length(inputTokens[tokenIndex].text);
            refreshHint();
            textIsDirty = true;
        }
    }

    inline function handleChar(char:Int):Void {
        if (char > 0) {

            if (inputTokens[tokenIndex] == null) inputTokens.push({text:'', type:PLAIN_TEXT, color:Colors.white()});

            var left:String = sub(inputTokens[tokenIndex].text, 0, caretIndex);
            var right:String = sub(inputTokens[tokenIndex].text, caretIndex);

            left += String.fromCharCode(char);
            caretIndex++;
            inputTokens[tokenIndex].text = left + right;
            refreshHint();
            textIsDirty = true;
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

    inline function stringifyToken(token:TextToken, caretIndex:Int, isHint:Bool, isEnabled:Bool):String {
        var str:String = '';

        if (caretIndex >= 0) {
            var left:String = sub(token.text, 0, caretIndex);
            var mid:String = sub(token.text, caretIndex, 1);
            var right:String = sub(token.text, caretIndex + 1);

            if (mid == '') mid = ' ';

            if (mid == ' ') caretStyle.start();
            else caretStyle.stop();

            str = left + caretStart + mid + styleEnd + right;
        } else {
            str = token.text;
        }

        return str;
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

    inline function refreshHint():Void {
        hintTokens = [];
        hintSignal.dispatch(inputTokens, {t:tokenIndex, c:caretIndex});
    }
}
