package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;
using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.ArrayUtils;

class Interpreter {

    // inline static var INPUT_PREFIX:String = '__input_';
    // inline static var OUTPUT_PREFIX:String = '__output_';
    // inline static var HINT_PREFIX:String = '__hint_';

    var console:ConsoleUIMediator;
    var state:ConsoleState;
    var commands:Map<String, ConsoleCommand>;

    public function new(console:ConsoleUIMediator):Void {
        this.console = console;
        this.console.keyboardSignal.add(handleKeyboard);
        this.console.clickSignal.add(handleSpanClick);
        state = blankState();
        commands = new Map();
        print();
    }

    public function addCommand(command:ConsoleCommand):Void {
        if (command != null) {
            if (commands[command.name] != null && commands[command.name] != command) {
                throw 'Existing command with name ${command.name}';
            }
            commands[command.name] = command;
        }
    }

    public function removeCommand(command:ConsoleCommand):Void {
        commands.remove(command.name);
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

        print();
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            state = blankState();
        } else if (alt) {
            if (state.currentToken.prev != null) {
                state.currentToken = state.currentToken.prev;
                state.caretIndex = length(state.currentToken.text);
            } else {
                state.currentToken.text = '';
                state.caretIndex = 0;
            }
            trimState();
        } else {
            if (state.caretIndex != 0) {
                var left:String = sub(state.currentToken.text, 0, state.caretIndex);
                var right:String = sub(state.currentToken.text, state.caretIndex);

                state.currentToken.text = sub(left, 0, length(left) - 1) + right;
                state.caretIndex--;
            } else if (state.currentToken.prev != null) {
                state.currentToken = state.currentToken.prev;
                state.caretIndex = length(state.currentToken.text);
            }
            trimState();
            validateState(false);
        }
    }

    inline function handleEnter():Void {
        // TODO: execution
    }

    inline function handleTab():Void {
        if (state.hints != null && state.hints.length > 0) {
            state.currentToken.text = state.hints[0].text;
            validateState(true);
            if (state.completionError == null && state.commandError == null) {
                state.currentToken.next = blankToken(state.currentToken);
                state.currentToken = state.currentToken.next;
                state.caretIndex = 0;
            } else {
                state.caretIndex = length(state.currentToken.text);
            }
        } else if (length(state.currentToken.text) == 0) {
            validateState(false);
        }
    }

    inline function handleEscape():Void {
        state = blankState();
        validateState(false);
    }

    inline function handleCaretLeft(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (state.currentToken.prev != null) state.currentToken = state.currentToken.prev;
            state.caretIndex = length(state.currentToken.text);
        } else if (alt) {
            if (state.currentToken.prev != null) state.currentToken = state.currentToken.prev;
            state.caretIndex = length(state.currentToken.text);
        } else {
            if (state.caretIndex == 0) {
                if (state.currentToken.prev != null) {
                    state.currentToken = state.currentToken.prev;
                    state.caretIndex = length(state.currentToken.text);
                }
            } else {
                state.caretIndex--;
            }
        }
    }

    inline function handleCaretRight(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (state.currentToken.next != null) state.currentToken = state.currentToken.next;
            state.caretIndex = length(state.currentToken.text);
        } else if (alt) {
            if (state.currentToken.next != null) state.currentToken = state.currentToken.next;
            state.caretIndex = length(state.currentToken.text);
        } else {
            if (state.caretIndex == length(state.currentToken.text)) {
                if (state.currentToken.next != null) {
                    state.currentToken = state.currentToken.next;
                    state.caretIndex = 0;
                }
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
            var left:String = sub(state.currentToken.text, 0, state.caretIndex);
            var right:String = sub(state.currentToken.text, state.caretIndex);
            var token:ConsoleToken = state.currentToken;
            if (char == ' ' && token.type != Tail) {
                if (length(token.text) == 0) {
                    validateState(false);
                } else {
                    validateState(true);
                    if (state.completionError == null && state.commandError == null) {
                        token.text = left;
                        token.next = blankToken(token);
                        token = token.next;
                        state.currentToken = token;
                        token.text = right;
                        state.caretIndex = length(right);
                    }
                }
            } else {
                var prev:ConsoleToken = token.prev;
                if (prev == null || prev.type != Key || state.currentCommand.keys[prev.text].indexOf(char) != -1) {
                    if (token.next != null || !(state.commandError != null || state.hintError != null)) {
                        token.text = left + char + right;
                        state.caretIndex++;
                        trimState();
                        validateState(false);
                    }
                }
            }
        }
    }

    inline function trimState():Void {
        var token:ConsoleToken = state.currentToken;

        while (token != null) {
            if (token.type != null) {
                switch (token.type) {
                    case Key: state.keyReg[token.text] = false;
                    case Flag: state.flagReg[token.text] = false;
                    case TailMarker: state.tailMarkerPresent = false;
                    case _:
                }
            }
            token = token.next;
        }

        state.currentToken.next = null;
    }

    function print():Void {

        var hintString:String = null;
        if (state.completionError != null) {
            hintString = '\t§{${Strings.ERROR_OUTPUT_STYLENAME}}${state.completionError}§{}';
        } else if (state.commandError != null) {
            hintString = '\t§{${Strings.ERROR_OUTPUT_STYLENAME}}${state.commandError}§{}';
        } else if (state.hintError != null) {
            hintString = '\t§{${Strings.ERROR_OUTPUT_STYLENAME}}${state.hintError}§{}';
        } else {
            hintString = printHints(state.hints);
        }
        console.setHint(hintString);
        trace(hintString);

        var inputString:String = printTokens(state.input);
        console.setInput(inputString);
        trace(inputString);
    }

    function handleSpanClick(id:String):Void {
        /*
        if (id.indexOf(INPUT_PREFIX) == 0) {

        } else if (id.indexOf(OUTPUT_PREFIX) == 0) {

        } else if (id.indexOf(HINT_PREFIX) == 0) {

        }
        */
    }

    function validateState(complete:Bool):Void {
        var completionError:String = null;
        var hintError:String = null;
        var commandError:String = null;
        var type:ConsoleTokenType = null;
        var prev:ConsoleToken = state.currentToken.prev;
        var currentText:String = state.currentToken.text;
        var hints:Array<ConsoleHint> = null;

        if (prev == null) {
            type = CommandName;
            if (complete) {
                if (commands[currentText] == null) {
                    completionError = 'Command not found.';
                } else {
                    var command:ConsoleCommand = commands[currentText];
                    state.currentCommand = command;
                    state.autoTail = command.flags.empty() && command.keys.empty();

                    var keyReg:Map<String, Bool> = new Map();
                    for (key in command.keys.keys()) keyReg[key] = false;
                    state.keyReg = keyReg;

                    var flagReg:Map<String, Bool> = new Map();
                    for (flag in command.flags) flagReg[flag] = false;
                    state.flagReg = flagReg;

                    state.tailMarkerPresent = false;
                }
            } else {
                hints = commands.keys().intoArray().filter(startsWith.bind(_, currentText)).map(argToHint.bind(_, CommandName));
                if (hints.empty()) hintError = 'No matches.';
                else hints.sort(alphabeticallyByName);
            }
        } else {
            switch (prev.type) {
                case Key:
                    type = Value;
                    state.currentToken.type = type;
                    if (complete) {
                        if (length(currentText) == 0) {
                            completionError = 'Empty value.';
                        }
                    }
                    // send to the command for further validation
                    // commandError
                case TailMarker:
                    type = Tail;
                    state.currentToken.type = type;
                case _:
                    trace('${state.autoTail} ${state.tailMarkerPresent} $currentText');
                    if (!state.autoTail && !state.tailMarkerPresent && currentText == ':') {
                        type = TailMarker;
                        if (complete) state.tailMarkerPresent = true;
                    } else {
                        if (complete) {
                            if (state.keyReg[currentText] == false) {
                                type = Key;
                                state.keyReg[currentText] = true;
                            } else if (state.keyReg[currentText] == true) {
                                completionError = 'Duplicate key.';
                            } else if (state.flagReg[currentText] == false) {
                                type = Flag;
                                state.flagReg[currentText] = true;
                            } else if (state.flagReg[currentText] == true) {
                                completionError = 'Duplicate flag.';
                            } else {
                                completionError = 'No matches found.';
                            }
                        } else {
                            var keys = state.keyReg.keys().intoArray().filter(isUnusedMatch.bind(_, state.keyReg, currentText));
                            var keyHints:Array<ConsoleHint> = keys.map(argToHint.bind(_, Key));

                            var flags = state.flagReg.keys().intoArray().filter(isUnusedMatch.bind(_, state.flagReg, currentText));
                            var flagHints:Array<ConsoleHint> = flags.map(argToHint.bind(_, Flag));

                            if (keyHints.empty() && flagHints.empty()) {
                                hintError = 'No matches.';
                            } else {
                                hints = keyHints.concat(flagHints);
                                hints.sort(alphabeticallyByName);
                            }
                        }
                    }
            }
        }

        if (complete) state.currentToken.type = type;
        trace(type);

        state.completionError = completionError;
        state.hintError = hintError;
        state.commandError = commandError;
        state.hints = hints;
    }

    function startsWith(arg:String, sub:String):Bool return arg.indexOf(sub) == 0;

    function isUnusedMatch(arg:String, argMap:Map<String, Bool>, sub:String):Bool {
        return !argMap[arg] && arg.indexOf(sub) == 0;
    }

    function argToHint(arg:String, type:ConsoleTokenType):ConsoleHint return {text:arg, type:type};

    function alphabeticallyByName(hint1:ConsoleHint, hint2:ConsoleHint):Int {
        if (hint1.text == hint2.text) return 0;
        else if (hint1.text > hint2.text) return 1;
        else return -1;
    }

    inline function printTokens(token:ConsoleToken):String {
        var str:String = null;
        if (token != null) {
            str = styleToken(token);
            if (token.next != null) str += ' ' + printTokens(token.next);
        }
        return str;
    }

    inline function printHints(hints:Array<ConsoleHint>):String {
        var hintStrings:Array<String> = [];
        if (hints != null) {
            for (hint in state.hints) {
                hintStrings.push('\t§{}${hint.text}§{}');
            }
        }
        return hintStrings.join('\n');
    }

    inline function styleToken(token:ConsoleToken):String {
        var str:String = token.text;
        var styleName:String = null; // TODO: map token types to style names
        if (token == state.currentToken) {
            str = sub(str, 0, state.caretIndex) + CARET + sub(str, state.caretIndex);
        }
        if (token.next == null && (state.completionError != null || state.commandError != null || state.hintError != null)) {
            styleName = Strings.ERROR_INPUT_STYLENAME;
        }
        if (styleName == null) styleName = Strings.INPUT_STYLENAME;
        return '§{$styleName}$str§{}';
    }

    inline static function blankState():ConsoleState {
        var tok = blankToken();
        return {input:tok, output:null, hint:null, currentToken:tok, caretIndex:0};
    }

    inline static function blankToken(prev:ConsoleToken = null, next:ConsoleToken = null):ConsoleToken {
        return {text:'', type:null, prev:prev, next:next};
    }
}
