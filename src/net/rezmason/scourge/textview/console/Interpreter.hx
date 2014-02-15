package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;
import haxe.Timer;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;
using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.ArrayUtils;

enum InterpreterState {
    Idle;
    Hinting;
    Executing;
}

class Interpreter {

    // inline static var INPUT_PREFIX:String = '__input_';
    // inline static var OUTPUT_PREFIX:String = '__output_';
    // inline static var HINT_PREFIX:String = '__hint_';

    var console:ConsoleUIMediator;
    var cState:ConsoleState;
    var iState:InterpreterState;
    var commands:Map<String, ConsoleCommand>;

    public function new(console:ConsoleUIMediator):Void {
        this.console = console;
        this.console.keyboardSignal.add(handleKeyboard);
        this.console.clickSignal.add(handleSpanClick);
        cState = blankState();
        iState = Idle;
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

        if (key != Keyboard.LEFT && key != Keyboard.RIGHT) checkForCommandHintCondition();

        print();
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            cState = blankState();
        } else if (alt) {
            if (cState.currentToken.prev != null) {
                cState.currentToken = cState.currentToken.prev;
                cState.caretIndex = length(cState.currentToken.text);
            } else {
                cState.currentToken.text = '';
                cState.caretIndex = 0;
            }
            trimState();
        } else {
            if (cState.caretIndex != 0) {
                var left:String = sub(cState.currentToken.text, 0, cState.caretIndex);
                var right:String = sub(cState.currentToken.text, cState.caretIndex);

                cState.currentToken.text = sub(left, 0, length(left) - 1) + right;
                cState.caretIndex--;
            } else if (cState.currentToken.prev != null) {
                cState.currentToken = cState.currentToken.prev;
                cState.caretIndex = length(cState.currentToken.text);
            }
            trimState();
            validateState(false);
        }
    }

    inline function handleEnter():Void {
        validateState(true);
        if (cState.completionError == null) waitForCommandExecution();
    }

    inline function handleTab():Void {
        if (cState.hints != null && cState.hints.length > 0) {
            cState.currentToken.text = cState.hints[0].text;
            validateState(true);
            if (cState.completionError == null) {
                cState.currentToken.next = blankToken(cState.currentToken);
                cState.currentToken = cState.currentToken.next;
                cState.caretIndex = 0;
            } else {
                cState.caretIndex = length(cState.currentToken.text);
            }
        } else if (length(cState.currentToken.text) == 0) {
            validateState(false);
        }
    }

    inline function handleEscape():Void {
        cState = blankState();
        validateState(false);
    }

    inline function handleCaretLeft(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (cState.currentToken.prev != null) cState.currentToken = cState.currentToken.prev;
            cState.caretIndex = length(cState.currentToken.text);
        } else if (alt) {
            if (cState.currentToken.prev != null) cState.currentToken = cState.currentToken.prev;
            cState.caretIndex = length(cState.currentToken.text);
        } else {
            if (cState.caretIndex == 0) {
                if (cState.currentToken.prev != null) {
                    cState.currentToken = cState.currentToken.prev;
                    cState.caretIndex = length(cState.currentToken.text);
                }
            } else {
                cState.caretIndex--;
            }
        }
    }

    inline function handleCaretRight(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (cState.currentToken.next != null) cState.currentToken = cState.currentToken.next;
            cState.caretIndex = length(cState.currentToken.text);
        } else if (alt) {
            if (cState.currentToken.next != null) cState.currentToken = cState.currentToken.next;
            cState.caretIndex = length(cState.currentToken.text);
        } else {
            if (cState.caretIndex == length(cState.currentToken.text)) {
                if (cState.currentToken.next != null) {
                    cState.currentToken = cState.currentToken.next;
                    cState.caretIndex = 0;
                }
            } else {
                cState.caretIndex++;
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
            var left:String = sub(cState.currentToken.text, 0, cState.caretIndex);
            var right:String = sub(cState.currentToken.text, cState.caretIndex);
            var token:ConsoleToken = cState.currentToken;
            if (char == ' ' && token.type != Tail) {
                if (length(token.text) == 0) {
                    validateState(false);
                } else {
                    validateState(true);
                    if (cState.completionError == null) {
                        token.text = left;
                        token.next = blankToken(token);
                        token = token.next;
                        cState.currentToken = token;
                        token.text = right;
                        cState.caretIndex = length(right);
                    }
                }
            } else {
                var prev:ConsoleToken = token.prev;
                if (prev == null || prev.type != Key || cState.currentCommand.keys[prev.text].indexOf(char) != -1) {
                    if (token.next != null || cState.hintError == null) {
                        token.text = left + char + right;
                        cState.caretIndex++;
                        trimState();
                        validateState(false);
                    }
                }
            }
        }
    }

    inline function trimState():Void {
        var token:ConsoleToken = cState.currentToken;

        while (token != null) {
            if (token.type != null) {
                switch (token.type) {
                    case Key: cState.keyReg[token.text] = false;
                    case Flag: cState.flagReg[token.text] = false;
                    case TailMarker: cState.tailMarkerPresent = false;
                    case _:
                }
            }
            token = token.next;
        }

        cState.currentToken.next = null;
    }

    function print():Void {
        var hintString:String = null;
        if (cState.completionError != null) {
            hintString = '\t§{${Strings.ERROR_OUTPUT_STYLENAME}}${cState.completionError}§{}';
        } else if (cState.hintError != null) {
            hintString = '\t§{${Strings.ERROR_OUTPUT_STYLENAME}}${cState.hintError}§{}';
        } else {
            hintString = printHints(cState.hints);
        }
        console.setHint(hintString);

        var inputString:String = printTokens(cState.input);
        console.setInput(inputString);
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
        var type:ConsoleTokenType = null;
        var prev:ConsoleToken = cState.currentToken.prev;
        var currentText:String = cState.currentToken.text;
        var hints:Array<ConsoleHint> = null;

        if (prev == null) {
            type = CommandName;
            if (complete) {
                if (commands[currentText] == null) {
                    completionError = 'Command not found.';
                } else {
                    var command:ConsoleCommand = commands[currentText];
                    cState.currentCommand = command;
                    cState.autoTail = command.flags.empty() && command.keys.empty();

                    var keyReg:Map<String, Bool> = new Map();
                    for (key in command.keys.keys()) keyReg[key] = false;
                    cState.keyReg = keyReg;

                    var flagReg:Map<String, Bool> = new Map();
                    for (flag in command.flags) flagReg[flag] = false;
                    cState.flagReg = flagReg;

                    cState.tailMarkerPresent = false;
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
                    cState.currentToken.type = type;
                    if (complete && length(currentText) == 0) {
                        completionError = 'Empty value.';
                    }
                case TailMarker:
                    type = Tail;
                    cState.currentToken.type = type;
                case _:
                    if (!cState.autoTail && !cState.tailMarkerPresent && currentText == ':') {
                        type = TailMarker;
                        if (complete) cState.tailMarkerPresent = true;
                    } else {
                        if (complete) {
                            if (cState.keyReg[currentText] == false) {
                                type = Key;
                                cState.keyReg[currentText] = true;
                            } else if (cState.keyReg[currentText] == true) {
                                completionError = 'Duplicate key.';
                            } else if (cState.flagReg[currentText] == false) {
                                type = Flag;
                                cState.flagReg[currentText] = true;
                            } else if (cState.flagReg[currentText] == true) {
                                completionError = 'Duplicate flag.';
                            } else {
                                completionError = 'No matches found.';
                            }
                        } else {
                            var keys = cState.keyReg.keys().intoArray().filter(isUnusedMatch.bind(_, cState.keyReg, currentText));
                            var keyHints:Array<ConsoleHint> = keys.map(argToHint.bind(_, Key));

                            var flags = cState.flagReg.keys().intoArray().filter(isUnusedMatch.bind(_, cState.flagReg, currentText));
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

        if (complete) cState.currentToken.type = type;
        // trace(type);

        cState.completionError = completionError;
        cState.hintError = hintError;
        cState.hints = hints;
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

    inline function bakeArgs():Void {
        if (cState.currentCommand != null) {
            if (cState.args == null) cState.args = {flags:[], keyValuePairs:new Map(), tail:null};

            var flags:Array<String> = cState.args.flags;
            var keyValuePairs:Map<String, String> = cState.args.keyValuePairs;
            var tail:String = null;
            var pendingKey:String = null;
            var pendingValue:String = null;

            flags.splice(0, flags.length);
            for (key in keyValuePairs.keys()) keyValuePairs.remove(key);

            var token:ConsoleToken = cState.input;
            while (token != null) {
                if (token.type != null) {
                    switch (token.type) {
                        case Flag: flags.push(token.text);
                        case Key if (token.next != null):
                            if (token.next.type == null) {
                                pendingKey = token.text;
                                pendingValue = token.next.text;
                            } else {
                                keyValuePairs[token.text] = token.next.text;
                            }
                            token = token.next;
                        case Tail: tail = token.text;
                        case _:
                    }
                }
                token = token.next;
            }

            cState.args.tail = tail;
            cState.args.pendingKey = pendingKey;
            cState.args.pendingValue = pendingValue;
        }
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
            for (hint in cState.hints) {
                hintStrings.push('\t§{}${hint.text}§{}');
            }
        }
        return hintStrings.join('\n');
    }

    inline function styleToken(token:ConsoleToken):String {
        var str:String = token.text;
        var styleName:String = null; // TODO: map token types to style names
        if (token == cState.currentToken) {
            str = sub(str, 0, cState.caretIndex) + CARET + sub(str, cState.caretIndex);
        }
        if (token.next == null && (cState.completionError != null || cState.hintError != null)) {
            styleName = Strings.ERROR_INPUT_STYLENAME;
        }
        if (styleName == null) styleName = Strings.INPUT_STYLENAME;
        return '§{$styleName}$str§{}';
    }

    inline function checkForCommandHintCondition():Void {
        if (iState == Idle && cState.currentCommand != null) {
            var lastToken:ConsoleToken = cState.input;
            while (lastToken.next != null) lastToken = lastToken.next;
            var tokenIsEmpty:Bool = length(lastToken.text) == 0;

            if (lastToken.type == Value && !tokenIsEmpty) {
                waitForCommandHints();
            } else if (tokenIsEmpty && (lastToken.prev.type == Flag || lastToken.prev.type == Value)) {
                waitForCommandHints();
            }
        }
    }

    function waitForCommandHints():Void {
        bakeArgs();
        console.freeze();
        iState = Hinting;
        cState.currentCommand.outputSignal.add(onCommandHint);
        Timer.delay(function() cState.currentCommand.hint(cState.args), 0);
    }

    function onCommandHint(outputString:String, done:Bool):Void {
        console.setHint('\t' + outputString);
        cState.currentCommand.outputSignal.remove(onCommandHint);
        iState = Idle;
        console.unfreeze();
    }

    function waitForCommandExecution():Void {
        bakeArgs();
        console.freeze();
        iState = Executing;
        cState.currentCommand.outputSignal.add(onCommandExecute);
        Timer.delay(function() cState.currentCommand.execute(cState.args), 0);
    }

    function onCommandExecute(outputString:String, done:Bool):Void {
        // Do something with outputString
        trace(outputString);
        if (done) {
            cState.currentCommand.outputSignal.remove(onCommandHint);
            iState = Idle;
            console.unfreeze();
        }
    }

    inline static function blankState():ConsoleState {
        var tok = blankToken();
        return {input:tok, output:null, hint:null, currentToken:tok, caretIndex:0};
    }

    inline static function blankToken(prev:ConsoleToken = null, next:ConsoleToken = null):ConsoleToken {
        return {text:'', type:null, prev:prev, next:next};
    }
}
