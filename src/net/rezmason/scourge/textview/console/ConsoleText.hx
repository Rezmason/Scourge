package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;

import haxe.Timer;

import msignal.Signal;

import net.rezmason.scourge.textview.console.Types;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.AnimatedStyle;
import net.rezmason.utils.Utf8Utils.*;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef FrozenInteraction = {
    var id:Int;
    var interaction:Interaction;
}

class ConsoleText extends UIText {

    public var hintSignal(default, null):Signal2<Array<TextToken>, {t:Int, c:Int}>;
    public var execSignal(default, null):Signal1<Array<TextToken>>;

    public var frozen(get, set):Bool;
    var waiting:Bool;

    var prompt:String;
    var caretStart:String;
    var caretIndex:Int;
    var tokenIndex:Int;
    var outputString:String;
    var hintString:String;
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

    public function new():Void {

        super();

        styles.extract(Strings.BREATHING_PROMPT_STYLE);
        styles.extract(Strings.CARET_STYLE);
        styles.extract(Strings.WAIT_STYLES);
        styles.extract(Strings.INPUT_STYLE);

        setPlayer('rezmason', 0xFF3030);

        caretStyle = cast styles.getStyleByName('caret');
        caretStart = '§{caret}';

        caretIndex = 0;
        tokenIndex = 0;

        outputString = '';
        hintString = '';

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

    override function combineText():String {
        /*
        trace(inputTokens.map(stringifyToken.bind(_, -1, false, true)).join('|'));
        trace('$tokenIndex $caretIndex');
        */

        var combinedText:String = mainText;
        if (length(mainText) > 0) combinedText += '\n';
        combinedText += outputString;

        if (waiting) {
            combinedText += Strings.WAIT_INDICATOR;
        } else {
            combinedText += prompt;
            for (ike in 0...inputTokens.length) {
                var index:Int = ike == tokenIndex ? caretIndex : -1;
                combinedText += stringifyToken(inputTokens[ike], index, false, true) + ' ';
            }

            if (hintTokens.length > 0) {
                combinedText += '\n\t';
                for (token in hintTokens) combinedText += stringifyToken(token, -1, true, true) + ' ';
            }
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
                    case Keyboard.LEFT: handleLeft(alt, ctrl);
                    case Keyboard.RIGHT: handleRight(alt, ctrl);
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
        outputString = '';
        for (token in outputTokens) outputString += stringifyToken(token, -1, false, true);
        outputString += '\n';
        textIsDirty = true;
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            inputTokens = [{text:'', type:PLAIN_TEXT, color:Colors.white()}];
            caretIndex = 0;
            tokenIndex = 0;
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
        }

        dispatchHintSignal();
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
            dispatchExecSignal();
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
        // I dunno
    }

    inline function handleEscape():Void {
        inputTokens = [{text:'', type:PLAIN_TEXT, color:Colors.white()}];
        caretIndex = 0;
        tokenIndex = 0;
        dispatchHintSignal();
        textIsDirty = true;
    }

    inline function handleLeft(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            tokenIndex = 0;
            caretIndex = length(inputTokens[tokenIndex].text);
        } else if (alt) {
            prevToken();
        } else {
            caretIndex--;
            if (caretIndex < 0) {
                if (!prevToken()) caretIndex = 0;
            }
        }
        dispatchHintSignal();
        textIsDirty = true;
    }

    inline function handleRight(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            tokenIndex = inputTokens.length - 1;
            caretIndex = length(inputTokens[tokenIndex].text);
        } else if (alt) {
            nextToken();
        } else {
            caretIndex++;
            var len:Int = length(inputTokens[tokenIndex].text);
            if (caretIndex > len) {
                if (!nextToken()) caretIndex = len;
            }
        }
        dispatchHintSignal();
        textIsDirty = true;
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
            dispatchHintSignal();
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
            dispatchHintSignal();
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
            dispatchHintSignal();
            textIsDirty = true;
        }
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

    inline function dispatchHintSignal():Void {
        var tokens:Array<TextToken> = inputTokens.copy();
        var indices = {t:tokenIndex, c:caretIndex};
        Timer.delay(function() {
            hintTokens = [];
            textIsDirty = true;
            hintSignal.dispatch(inputTokens, indices);
        }, 10);
    }

    inline function dispatchExecSignal():Void {
        var tokens:Array<TextToken> = inputTokens.copy();
        Timer.delay(function() execSignal.dispatch(tokens), 10);
    }
}
