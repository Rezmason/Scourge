package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;

import haxe.Timer;
import haxe.Utf8;

import msignal.Signal;

import net.rezmason.scourge.textview.console.Types;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.Sigil;
import net.rezmason.scourge.textview.text.AnimatedStyle;
import net.rezmason.scourge.textview.text.Style;
import net.rezmason.scourge.textview.text.ButtonStyle;
import net.rezmason.scourge.textview.text.InputStyle;
import net.rezmason.utils.FlatFont;
import net.rezmason.utils.Utf8Utils.*;

using net.rezmason.scourge.textview.core.GlyphUtils;

private typedef FrozenInteraction = { id:Int, interaction:Interaction };
private typedef HistEntry = { val:Array<TextToken>, ?next:HistEntry, ?prev:HistEntry };

class ConsoleText extends UIText {

    public var hintSignal(default, null):Signal2<Array<TextToken>, InputInfo>;
    public var execSignal(default, null):Signal1<Array<TextToken>>;

    public var frozen(get, set):Bool;
    var waiting:Bool;

    var caretStyle:AnimatedStyle;

    var prompt:String;
    var caretIndex(default, set):Int;
    var caretCharCode:Int;
    var tokenIndex:Int;
    var outputString:String;
    var hintString:String;
    var inputTokens:Array<TextToken>;
    var outputTokens:Array<TextToken>;
    var hintTokens:Array<TextToken>;

    var lastHistEntry:HistEntry;
    var curHistEntry:HistEntry;

    var currentPlayerName:String;
    var currentPlayerColor:Int;

    var frozenQueue:List<FrozenInteraction>;
    var _frozen:Bool;

    public function new():Void {

        super();

        styles.extract(Strings.BREATHING_PROMPT_STYLE);
        styles.extract(Strings.CARET_STYLE);
        styles.extract(Strings.WAIT_STYLES);

        setPlayer('rezmason', 0x30FF00);

        caretStyle = cast styles.getStyleByName('caret');
        caretCharCode = Utf8.charCodeAt(Strings.CARET_CHAR, 0);

        caretIndex = 0;
        tokenIndex = 0;

        outputString = '';
        hintString = '';

        outputTokens = [];
        hintTokens = [];

        lastHistEntry = {val:[blankToken()]};
        curHistEntry = lastHistEntry;
        inputTokens = curHistEntry.val.map(copyToken);

        hintSignal = new Signal2();
        execSignal = new Signal1();

        frozenQueue = new List();
        frozen = false;
        waiting = false;
    }

    public inline function declareStyles(dec:String):Void styles.extract(dec);

    override public function styleCaret(caretGlyph:Glyph, font:FlatFont):Void {
        caretStyle.removeAllGlyphs();
        caretStyle.addGlyph(caretGlyph);
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
        '∂{name:head_$promptStyleName, basis:breathingprompt, r:$r, g:$g, b:$b}Ω' +
        '§{name:$promptStyleName, r:$r, g:$g, b:$b} $currentPlayerName§{}' + Strings.PROMPT + styleEnd;
    }

    override function combineText():String {
        var combinedText:String = mainText;

        if (length(mainText) > 0) combinedText += '\n';

        combinedText += outputString;

        if (waiting) {
            combinedText += Strings.WAIT_INDICATOR;
        } else {
            combinedText += prompt + printTokens(inputTokens, ' ', tokenIndex, caretIndex);
            combinedText += '\n'; // Always added, because there's always input
            if (hintTokens.length > 0) combinedText += '\t' + printTokens(hintTokens, '\n\t');
        }

        return combinedText;
    }

    override public function interact(id:Int, interaction:Interaction):Void {

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
            case _: super.interact(id, interaction);
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
        if (outputTokens.length > 0) outputString = '\t' + printTokens(outputTokens, '\n\t') + '\n';
        else outputString = '';
        textIsDirty = true;
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
                textIsDirty = true;
            }
        } else {
            var left:String = sub(inputTokens[tokenIndex].text, 0, caretIndex);
            var right:String = sub(inputTokens[tokenIndex].text, caretIndex);

            if (length(left) > 0) {
                var lim:Int = alt ? 0 : length(left) - 1;
                if (lim == -1) lim = 0;
                left = sub(left, 0, lim);
                caretIndex = lim;
            }

            inputTokens[tokenIndex].text = left + right;
            textIsDirty = true;
        }

        dispatchHintSignal(Strings.BACKSPACE());
    }

    inline function handleEnter():Void {
        var isEmpty:Bool = inputTokens.length == 1 && length(inputTokens[0].text) == 0;

        if (length(mainText) > 0) mainText += '\n';

        var oldOutputString:String = '';
        if (outputTokens.length > 0) oldOutputString = '\t' + printTokens(outputTokens, '\n\t') + '\n';
        mainText += oldOutputString;

        mainText += prompt + printTokens(inputTokens, ' ');

        if (!isEmpty) {
            frozen = true;
            waiting = true;
            appendHistEntry(inputTokens);
            dispatchExecSignal();
        }

        loadInputFromHistEntry(lastHistEntry);
        hintTokens = [];
        outputTokens = [];
        outputString = '';
    }

    inline function handleTab():Void dispatchHintSignal();

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
        textIsDirty = true;
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
        textIsDirty = true;
    }

    inline function handleChar(charCode:Int):Void {
        if (charCode > 0) {
            if (inputTokens[tokenIndex] == null) inputTokens.push(blankToken());

            var left:String = sub(inputTokens[tokenIndex].text, 0, caretIndex);
            var right:String = sub(inputTokens[tokenIndex].text, caretIndex);

            var char:String = String.fromCharCode(charCode);
            left += char;
            caretIndex++;
            inputTokens[tokenIndex].text = left + right;
            dispatchHintSignal(char);
            textIsDirty = true;
        }
    }

    inline function printTokens(tokens:Array<TextToken>, sep:String, tokenIndex:Int = -1, caretIndex:Int = -1):String {
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

        var styleName:String = token.styleName;
        var styleTag:String = styleEnd;
        var style:Style = styles.getStyleByName(styleName);
        if (styleName != null && style != null) {
            var sigil:String = '';
            switch (token.type) {
                case SHORTCUT(insert):
                    var buttonStyle:ButtonStyle = cast style;
                    sigil = Sigil.BUTTON_STYLE;
                    // TODO
                case CAPSULE(type, name, valid):
                    var inputStyle:InputStyle = cast style;
                    sigil = Sigil.INPUT_STYLE;
                    // TODO
                case _:
                    sigil = (Std.is(style, AnimatedStyle) ? Sigil.ANIMATED_STYLE : Sigil.STYLE);
            }
            styleTag = '$sigil{$styleName}';
        } else {
            styleTag = styleEnd;
        }
        return styleTag + token.text + styleEnd;
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

    inline function dispatchHintSignal(char:String = ''):Void {
        var tokens:Array<TextToken> = inputTokens.map(copyToken);
        var info:InputInfo = {tokenIndex:tokenIndex, caretIndex:caretIndex, char:char};
        hintTokens = [];
        textIsDirty = true;
        hintSignal.dispatch(inputTokens, info);
    }

    inline function dispatchExecSignal():Void {
        var tokens:Array<TextToken> = inputTokens.map(copyToken);
        Timer.delay(function() execSignal.dispatch(tokens), 1);
    }

    inline static function blankToken():TextToken return {text:'', type:PLAIN_TEXT};

    function copyToken(token:TextToken):TextToken return {text:token.text, type:token.type, styleName:token.styleName};

    inline function set_caretIndex(val:Int):Int {
        caretStyle.start(0);
        return this.caretIndex = val;
    }
}
