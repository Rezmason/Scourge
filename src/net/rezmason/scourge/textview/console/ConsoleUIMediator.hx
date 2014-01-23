package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;

import haxe.Timer;
import haxe.Utf8;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.*;
import net.rezmason.utils.FlatFont;
import net.rezmason.utils.Utf8Utils.*;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.textview.core.GlyphUtils;

private typedef FrozenInteraction = { id:Int, interaction:Interaction };
private typedef HistEntry = { val:Array<TextToken>, ?next:HistEntry, ?prev:HistEntry };

class ConsoleUIMediator extends UIMediator {

    inline static var INPUT_PREFIX:String = '__input_';
    inline static var OUTPUT_PREFIX:String = '__output_';
    inline static var HINT_PREFIX:String = '__hint_';

    public var hintSignal(default, null):Zig<Array<TextToken>->InputInfo->Void>;
    public var execSignal(default, null):Zig<Array<TextToken>->Void>;
    public var buttonSignal(default, null):Zig<TextToken->MouseInteractionType->Void>;

    public var frozen(get, set):Bool;
    var hintingPreExecution:Bool;
    var executing:Bool;

    var caretStyle:AnimatedStyle;
    var caretSpan:Span;

    var prompt:String;
    var caretIndex(default, set):Int;
    var caretCharCode:Int;
    var tokenIndex:Int;
    var outputString:String;
    var inputTokens:Array<TextToken>;
    var outputTokens:Array<TextToken>;
    var hintTokens:Array<TextToken>;

    var lastHistEntry:HistEntry;
    var curHistEntry:HistEntry;

    var currentPlayerName:String;
    var currentPlayerColor:Int;

    var frozenQueue:List<FrozenInteraction>;
    var _frozen:Bool;

    var interactiveDoc:Document;
    var appendedDoc:Document;

    var addedText:String;

    var isLogDocDirty:Bool;
    var isLogDocAppended:Bool;
    var isInteractiveDocDirty:Bool;

    public function new():Void {

        super();

        interactiveDoc = new Document();
        interactiveDoc.shareWith(compositeDoc);

        appendedDoc = new Document();
        appendedDoc.shareWith(compositeDoc);

        isLogDocDirty = false;
        isLogDocAppended = false;
        isInteractiveDocDirty = false;

        addedText = '';

        loadStyles([
            Strings.BREATHING_PROMPT_STYLE,
            Strings.WAIT_STYLES,
            Strings.INPUT_STYLE,
            Strings.ERROR_STYLES,
        ].join(''));

        setPlayer('rezmason', 0x30FF00);

        for (span in Parser.parse(Strings.CARET_STYLE).spans) if (Std.is(span.style, AnimatedStyle)) caretSpan = span;
        caretStyle = cast caretSpan.style;

        caretCharCode = Utf8.charCodeAt(Strings.CARET_CHAR, 0);

        caretIndex = 0;
        tokenIndex = 0;

        outputString = '';

        outputTokens = [];
        hintTokens = [];

        lastHistEntry = {val:[blankToken()]};
        curHistEntry = lastHistEntry;
        inputTokens = curHistEntry.val.map(copyToken);

        hintSignal = new Zig();
        execSignal = new Zig();
        buttonSignal = new Zig();

        frozenQueue = new List();
        frozen = false;
        executing = false;
        hintingPreExecution = false;

        isInteractiveDocDirty = true;
    }

    public inline function loadStyles(dec:String):Void compositeDoc.loadStyles(dec);

    override public function styleCaret(caretGlyph:Glyph, font:FlatFont):Void {
        caretSpan.removeAllGlyphs();
        caretSpan.addGlyph(caretGlyph);
        caretGlyph.set_char(caretCharCode, font);
    }

    public function setPlayer(name:String, color:Int):Void {
        currentPlayerName = name;
        currentPlayerColor = color;

        var r:Float = (color >> 16 & 0xFF) / 0xFF;
        var g:Float = (color >> 8  & 0xFF) / 0xFF;
        var b:Float = (color >> 0  & 0xFF) / 0xFF;

        var promptStyleName:String = 'prompt_' + currentPlayerName + Math.random();

        prompt =
        '∂{name:head_$promptStyleName, basis:${Strings.BREATHING_PROMPT_STYLENAME}, r:$r, g:$g, b:$b}Ω' +
        '§{name:$promptStyleName, r:$r, g:$g, b:$b} $currentPlayerName§{}' + Strings.PROMPT + '§{}';
    }

    override function combineDocs():Void {

        if (isLogDocDirty) {
            isLogDocDirty = false;
            logDoc.setText(swapTabsWithSpaces(mainText));
        }

        if (isLogDocAppended) {
            isLogDocAppended = false;

            mainText += addedText;
            appendedDoc.setText(swapTabsWithSpaces(addedText));
            appendedDoc.removeInteraction();
            logDoc.append(appendedDoc);
            appendedDoc.clear();
            appendedDoc.shareWith(logDoc);
            addedText = '';
        }

        if (isInteractiveDocDirty) {
            isInteractiveDocDirty = false;

            var interactiveText:String = (length(mainText) > 0 ? '\n' : '') + outputString;

            if (executing) {
                interactiveText += Strings.WAIT_INDICATOR;
            } else {
                interactiveText += prompt + printTokens(INPUT_PREFIX, inputTokens, ' ', tokenIndex, caretIndex);
                interactiveText += '\n'; // Always added, because there's always input
                if (hintTokens.length > 0) interactiveText += '\t' + printTokens(HINT_PREFIX, hintTokens, '\n\t');
            }

            interactiveDoc.setText(swapTabsWithSpaces(interactiveText));
        }

        compositeDoc.clear();
        compositeDoc.append(logDoc);
        compositeDoc.append(interactiveDoc);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {

        if (frozen) frozenQueue.add({id:id, interaction:interaction});

        switch (interaction) {
            case KEYBOARD(type, key, char, shift, alt, ctrl) if (type == KEY_DOWN || type == KEY_REPEAT):
                switch (key) {
                    case Keyboard.BACKSPACE: handleBackspace(alt, ctrl);
                    case Keyboard.ENTER: handleEnter();
                    case Keyboard.ESCAPE: handleEscape();
                    case Keyboard.LEFT: handleCaretNudge(alt, ctrl, true);
                    case Keyboard.RIGHT: handleCaretNudge(alt, ctrl);
                    case Keyboard.UP: handleUp();
                    case Keyboard.DOWN: handleDown();
                    case Keyboard.TAB: handleTab();
                    case _: handleChar(char);
                }
            case _: super.receiveInteraction(id, interaction);
        }
    }

    override function handleSpanMouseInteraction(span:Span, type:MouseInteractionType):Void {
        super.handleSpanMouseInteraction(span, type);
        if (span.id.indexOf(INPUT_PREFIX) == 0) {
            for (ike in 0...inputTokens.length) {
                if (inputTokens[ike].id == span.id) {
                    if (type == MOUSE_DOWN || type == MOUSE_UP) {
                        tokenIndex = ike;
                        caretIndex = length(inputTokens[tokenIndex].text);
                        isDirty = true;
                        isInteractiveDocDirty = true;
                    }
                    break;
                }
            }
        } else if (span.id.indexOf(OUTPUT_PREFIX) == 0) {
            for (token in outputTokens) {
                if (token.id == span.id) {
                    buttonSignal.dispatch(token, type);
                    break;
                }
            }
        } else if (span.id.indexOf(HINT_PREFIX) == 0) {
            for (token in hintTokens) {
                if (token.id == span.id) {
                    buttonSignal.dispatch(token, type);
                    break;
                }
            }
        }
    }

    override public function updateSpans(delta:Float):Void {
        caretStyle.updateSpan(caretSpan, delta);
        super.updateSpans(delta);
    }

    public function receiveHint(input:Array<TextToken>, tokenIndex:Int, caretIndex:Int, hint:Array<TextToken>):Void {
        this.inputTokens = input;
        this.tokenIndex = tokenIndex;
        this.caretIndex = caretIndex;
        this.hintTokens = hint;

        for (token in inputTokens) if (token.styleName == null) token.styleName = Strings.INPUT_STYLENAME;
        for (token in  hintTokens) if (token.styleName == null) token.styleName = Strings.INPUT_STYLENAME;

        if (hintingPreExecution) {
            hintingPreExecution = false;
            if (frozen) frozen = false;
            onExecHint();
        }

        isDirty = true;
        isInteractiveDocDirty = true;
    }

    public function receiveExec(output:Array<TextToken>, done:Bool):Void {
        if (done) {
            frozen = false;
            executing = false;
        }

        outputTokens = output;
        if (outputTokens.length > 0 && length(outputTokens.map(stringFromToken).join('')) > 0) {
            outputString = '\t${printTokens(OUTPUT_PREFIX, outputTokens, "\n\t")}\n';
        }
        else outputString = '';
        isDirty = true;
        isInteractiveDocDirty = true;
    }

    public function addToText(text:String):Void {
        addedText += text;
        isDirty = true;
        isLogDocAppended = true;
    }

    public function clearText():Void {
        mainText = '';
        addedText = '';
        isDirty = true;
        isLogDocDirty = true;
        isLogDocAppended = false;
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            loadInputFromHistEntry(lastHistEntry);
        } else if (alt) {
            // Essentially an alt-left. Commands are responsible for "resetting" the input tokens,
            // and they can tell from the input info that this change was due to a backspace op.
            if (tokenIndex > 0) {
                tokenIndex--;
                caretIndex = length(inputTokens[tokenIndex].text);
                isDirty = true;
                isInteractiveDocDirty = true;
            }
        } else {
            var left:String = sub(inputTokens[tokenIndex].text, 0, caretIndex);
            var right:String = sub(inputTokens[tokenIndex].text, caretIndex);

            if (length(left) > 0) {
                left = sub(left, 0, length(left) - 1);
                caretIndex--;
                inputTokens[tokenIndex].text = left + right;
            } else if (tokenIndex > 0) {
                tokenIndex--;
                caretIndex = length(inputTokens[tokenIndex].text);
            }


            isDirty = true;
            isInteractiveDocDirty = true;
        }

        dispatchHintSignal(Strings.BACKSPACE());
    }

    inline function handleEnter():Void {
        tokenIndex = inputTokens.length - 1;
        frozen = true;
        hintingPreExecution = true;
        dispatchHintSignal(' ');
    }

    private function onExecHint():Void {

        var isEmpty:Bool = inputTokens.length == 1 && length(inputTokens[0].text) == 0;

        var lastInteractiveText:String = (length(mainText) > 0 ? '\n' : '');

        var oldOutputString:String = '';
        if (outputTokens.length > 0 && length(outputTokens.map(stringFromToken).join('')) > 0) {
            oldOutputString = '\t${printTokens(OUTPUT_PREFIX, outputTokens, "\n\t")}\n';
        }
        lastInteractiveText += oldOutputString;
        lastInteractiveText += prompt + printTokens(INPUT_PREFIX, inputTokens, ' ');

        if (!isEmpty) {
            frozen = true;
            executing = true;
            appendHistEntry(inputTokens);
            dispatchExecSignal();
        }

        addToText(lastInteractiveText);

        loadInputFromHistEntry(lastHistEntry);
        hintTokens = [];
        outputTokens = [];
        outputString = '';
    }

    inline function handleTab():Void {
        if (hintTokens.length > 0) buttonSignal.dispatch(hintTokens[0], CLICK);
        else dispatchHintSignal();
    }

    inline function handleEscape():Void {
        loadInputFromHistEntry(lastHistEntry);
        dispatchHintSignal();
    }

    inline function handleCaretNudge(alt:Bool, ctrl:Bool, nudgeLeft:Bool = false):Void {

        var tokenLimit:Int = nudgeLeft ? 0 : inputTokens.length - 1;
        var sign:Int = nudgeLeft ? -1 : 1;

        if (ctrl) {
            tokenIndex = tokenLimit;
            caretIndex = length(inputTokens[tokenIndex].text);
        } else if (alt) {
            if (tokenIndex * sign < tokenLimit * sign) {
                tokenIndex += sign;
                caretIndex = length(inputTokens[tokenIndex].text);
            }
        } else {
            caretIndex += sign;
            var charIndex:Int = nudgeLeft ? 0 : length(inputTokens[tokenIndex].text);
            if (caretIndex * sign > charIndex * sign) {
                if (tokenIndex * sign < tokenLimit * sign) {
                    tokenIndex += sign;
                    caretIndex = nudgeLeft ? length(inputTokens[tokenIndex].text) : 0;
                } else {
                    caretIndex = charIndex;
                }
            }
        }
        dispatchHintSignal();
        isDirty = true;
        isInteractiveDocDirty = true;
    }

    inline function handleUp():Void {
        loadInputFromHistEntry(curHistEntry.prev);
        dispatchHintSignal();
    }

    inline function handleDown():Void {
        loadInputFromHistEntry(curHistEntry.next);
        dispatchHintSignal();
    }

    inline function appendHistEntry(tokens:Array<TextToken>):Void {
        var histEntry:HistEntry = {val:tokens.map(copyToken), prev:lastHistEntry.prev, next:lastHistEntry};
        if (lastHistEntry.prev != null) lastHistEntry.prev.next = histEntry;
        lastHistEntry.prev = histEntry;
    }

    inline function loadInputFromHistEntry(histEntry:HistEntry):Void {
        if (histEntry != null) curHistEntry = histEntry;
        inputTokens = curHistEntry.val.map(copyToken);
        tokenIndex = inputTokens.length - 1;
        caretIndex = length(inputTokens[tokenIndex].text);
        isDirty = true;
        isInteractiveDocDirty = true;
    }

    inline function handleChar(charCode:Int):Void {
        if (charCode > 0) {
            if (inputTokens[tokenIndex] == null) inputTokens.push(blankToken());
            var char:String = String.fromCharCode(charCode);
            var restriction:String = inputTokens[tokenIndex].restriction;
            if (char == ' ' || restriction == null || restriction.indexOf(char) != -1) {
                var left:String = sub(inputTokens[tokenIndex].text, 0, caretIndex);
                var right:String = sub(inputTokens[tokenIndex].text, caretIndex);

                left += char;
                caretIndex++;
                inputTokens[tokenIndex].text = left + right;
                dispatchHintSignal(char);
            }
            isDirty = true;
            isInteractiveDocDirty = true;
        }
    }

    inline function printTokens(idPrefix:String, tokens:Array<TextToken>, sep:String, tokenIndex:Int = -1, caretIndex:Int = -1):String {
        for (ike in 0...tokens.length) tokens[ike].id = idPrefix + ike;
        var strings:Array<String> = tokens.map(styleToken);
        if (tokenIndex != -1 && caretIndex != -1) {
            var token:TextToken = copyToken(tokens[tokenIndex]);
            token.text = sub(token.text, 0, caretIndex) + Sigil.CARET + sub(token.text, caretIndex);
            strings[tokenIndex] = styleToken(token);
        }
        return strings.join(sep);
    }

    inline function styleToken(token:TextToken):String {
        var str:String = '';
        var styleTag:String = '§{}';
        var styleName:String = token.styleName;
        if (styleName != null && compositeDoc.getStyleByName(styleName) != null) {
            styleTag = Sigil.BUTTON_STYLE + '{name:$styleName, id:${token.id}}';
        }
        return styleTag + token.text + '§{}';
    }

    inline function get_frozen():Bool return _frozen;

    inline function set_frozen(val:Bool):Bool {
        if (_frozen && !val) {
            _frozen = false;
            while (!frozenQueue.isEmpty()) {
                var leftovers:FrozenInteraction = frozenQueue.pop();
                receiveInteraction(leftovers.id, leftovers.interaction);
            }
        }
        _frozen = val;
        return val;
    }

    inline function dispatchHintSignal(char:String = ''):Void {
        var tokens:Array<TextToken> = inputTokens.map(copyToken);
        var info:InputInfo = {tokenIndex:tokenIndex, caretIndex:caretIndex, char:char};
        hintTokens = [];
        isDirty = true;
        isInteractiveDocDirty = true;
        hintSignal.dispatch(inputTokens, info);
    }

    inline function dispatchExecSignal():Void {
        var tokens:Array<TextToken> = inputTokens.map(copyToken);
        Timer.delay(function() execSignal.dispatch(tokens), 1);
    }

    inline function stringFromToken(token:TextToken):String return token.text;

    inline static function blankToken():TextToken return {text:'', styleName:Strings.INPUT_STYLENAME};

    function copyToken(token:TextToken):TextToken {
        var copy:TextToken = {text:token.text};
        copy.id = token.id;
        copy.authorID = token.authorID;
        copy.styleName = token.styleName;
        copy.restriction = token.restriction;
        copy.hintData = token.hintData;
        return copy;
    }

    inline function set_caretIndex(val:Int):Int {
        caretStyle.startSpan(caretSpan, 0);
        return this.caretIndex = val;
    }
}
