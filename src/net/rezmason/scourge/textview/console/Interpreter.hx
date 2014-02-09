package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Utf8Utils.*;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Interpreter {

    // inline static var INPUT_PREFIX:String = '__input_';
    // inline static var OUTPUT_PREFIX:String = '__output_';
    // inline static var HINT_PREFIX:String = '__hint_';

    var console:ConsoleUIMediator;

    var state:ConsoleState;

    public function new(console:ConsoleUIMediator):Void {
        this.console = console;
        this.console.keyboardSignal.add(handleKeyboard);
        this.console.clickSignal.add(handleSpanClick);
        state = blankState();
    }

    function handleKeyboard(key:Int, charCode:Int, alt:Bool, ctrl:Bool):Void {
        switch (key) {
            case Keyboard.BACKSPACE: handleBackspace(alt, ctrl);
            case Keyboard.ENTER: handleEnter();
            case Keyboard.ESCAPE: handleEscape();
            case Keyboard.LEFT: handleCaretLeft(alt, ctrl);
            case Keyboard.RIGHT: handleCaretRight(alt, ctrl);
            case Keyboard.UP: handleUp();
            case Keyboard.DOWN: handleDown();
            case Keyboard.TAB: handleTab();
            case _: handleChar(charCode);
        }

        if (state.currentToken.next != null) validateInput();
        console.setInput(printToken(state.input));
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            state = blankState();
        } else if (alt) {
            if (state.currentToken.prev != null) {
                state.currentToken = state.currentToken.prev;
                state.caretIndex = length(state.currentToken.text) - 1;
            } else {
                state.currentToken.text = '';
                state.caretIndex = 0;
            }
        } else {
            if (state.caretIndex != 0) {
                state.currentToken.text = sub(state.currentToken.text, 0, length(state.currentToken.text) - 1);
                state.caretIndex--;
            } else if (state.currentToken.prev != null) {
                state.currentToken = state.currentToken.prev;
                state.caretIndex = length(state.currentToken.text) - 1;
            }
        }
        state.currentToken.next = null;
    }

    inline function handleEnter():Void {
        // TODO: execution
    }

    inline function handleTab():Void {
        // TODO: completion
    }

    inline function handleEscape():Void {
        state = blankState();
    }

    inline function handleCaretLeft(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (state.currentToken.prev != null) state.currentToken = state.currentToken.prev;
            state.caretIndex = length(state.currentToken.text) - 1;
        } else if (alt) {
            if (state.currentToken.prev != null) state.currentToken = state.currentToken.prev;
            state.caretIndex = length(state.currentToken.text) - 1;
        } else {
            if (state.caretIndex == 0) {
                if (state.currentToken.prev != null) state.currentToken = state.currentToken.prev;
            } else {
                state.caretIndex--;
            }
        }
    }

    inline function handleCaretRight(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (state.currentToken.next != null) state.currentToken = state.currentToken.next;
            state.caretIndex = length(state.currentToken.text) - 1;
        } else if (alt) {
            if (state.currentToken.next != null) state.currentToken = state.currentToken.next;
            state.caretIndex = length(state.currentToken.text) - 1;
        } else {
            if (state.caretIndex == length(state.currentToken.text) - 1) {
                if (state.currentToken.next != null) state.currentToken = state.currentToken.next;
            } else {
                state.caretIndex++;
            }
        }
    }

    inline function handleUp():Void {
        // TODO: history
    }

    inline function handleDown():Void {
        // TODO: history
    }

    inline function handleChar(charCode:Int):Void {
        if (charCode > 0) {
            var char:String = String.fromCharCode(charCode);
            if (char == ' ' && state.currentToken.invalidReason == null) {
                state.currentToken.next = blankToken(state.currentToken);
                state.currentToken = state.currentToken.next;
                state.caretIndex = 0;
            } else {
                state.currentToken.text += char;
                state.caretIndex++;
            }
            state.currentToken.next = null;
        }
    }

    function handleSpanClick(id:String):Void {
        /*
        if (id.indexOf(INPUT_PREFIX) == 0) {

        } else if (id.indexOf(OUTPUT_PREFIX) == 0) {

        } else if (id.indexOf(HINT_PREFIX) == 0) {

        }
        */
    }

    inline function printTokens(token:ConsoleToken):String {
        var str:String = null;
        if (token != null) {
            str = printToken(token);
            if (token.next != null) str += ' ' + printTokens(token.next);
        }
        return str;
    }

    inline function printToken(token:ConsoleToken):String {
        var str:String = token.text;
        if (token == state.currentToken) str = sub(str, 0, state.caretIndex) + '¢' + sub(str, state.caretIndex);
        return str;
    }

    inline function validateInput():Void {
        var token:ConsoleToken = state.input;
        while (token != null) {
            // TODO: validate
            token = token.next;
        }
    }

    inline static function blankState():ConsoleState {
        var tok = blankToken();
        return {input:tok, output:null, hint:null, currentToken:tok, caretIndex:0};
    }

    inline static function blankToken(prev:ConsoleToken = null, next:ConsoleToken = null):ConsoleToken {
        return {text:'', prev:prev, next:next};
    }
}
