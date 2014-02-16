package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;

import haxe.Timer;
import haxe.Utf8;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;
using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.ArrayUtils;

class Interpreter {

    static var styleNamesByType:Map<ConsoleTokenType, String> = makeStyleNamesByType();

    var currentToken(get, set):ConsoleToken;
    var caretIndex(get, set):Int;

    var console:ConsoleUIMediator;
    var cState:ConsoleState;
    var iState:InterpreterState;
    var commands:Map<String, ConsoleCommand>;
    var runningCommand:ConsoleCommand;
    var prompt:String;
    var commandHintString:String;
    var outputString:String;
    var combinedString:String;
    var cHistory:Array<String>;
    var mHistory:Array<String>;
    var mHistIndex:Int = 0;

    var tokensByID:Map<String, ConsoleToken>;
    var hintsByID:Map<String, ConsoleToken>;

    public function new(console:ConsoleUIMediator):Void {
        setPrompt('scourge', 0x3060FF);
        this.console = console;
        this.console.keyboardSignal.add(handleKeyboard);
        this.console.clickSignal.add(handleMouseInteraction);
        cState = blankState();
        cHistory = [''];
        mHistory = cHistory.copy();
        mHistIndex = 0;

        iState = Idle;
        commands = new Map();
        runningCommand = null;

        console.loadStyles([
            Strings.BREATHING_PROMPT_STYLE,
            Strings.WAIT_STYLES,
            Strings.COMMAND_HINT_STYLE,
            Strings.INPUT_STYLE,
            Strings.ERROR_STYLES,
            Strings.INTERPRETER_STYLES,
        ].join(''));

        commandHintString = '';
        outputString = '';

        tokensByID = new Map();
        hintsByID = new Map();
        combineStrings();
        printInteractiveText();
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

    public function setPrompt(name:String, color:Int):Void {

        var r:Float = (color >> 16 & 0xFF) / 0xFF;
        var g:Float = (color >> 8  & 0xFF) / 0xFF;
        var b:Float = (color >> 0  & 0xFF) / 0xFF;

        prompt =
        '∂{name:head_prompt_$name, basis:${Strings.BREATHING_PROMPT_STYLENAME}, r:$r, g:$g, b:$b}Ω' +
        '§{name:prompt_$name, r:$r, g:$g, b:$b} $name§{}${Strings.PROMPT}§{}';
    }

    function handleKeyboard(key:Int, charCode:Int, alt:Bool, ctrl:Bool):Void {

        tokensByID = new Map();
        hintsByID = new Map();

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
        else commandHintString = '';

        combineStrings();
        printInteractiveText();
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            cState = blankState();
        } else {
            if (alt) {
                if (currentToken.prev != null) {
                    currentToken = currentToken.prev;
                    caretIndex = length(currentToken.text);
                    trimState();
                } else {
                    trimState();
                    currentToken.text = '';
                    caretIndex = 0;
                }
            } else {
                if (caretIndex != 0) {
                    var left:String = sub(currentToken.text, 0, caretIndex);
                    var right:String = sub(currentToken.text, caretIndex);
                    trimState();
                    currentToken.text = sub(left, 0, length(left) - 1) + right;
                    caretIndex--;
                } else if (length(currentToken.text) == 0 && currentToken.prev != null) {
                    currentToken = currentToken.prev;
                    caretIndex = length(currentToken.text);
                    trimState();
                }
            }

            validateState(false);
        }
    }

    inline function handleEnter():Void {
        validateState(true, true);
        if (cState.completeError == null && cState.finalError == null) {
            cState.hints = null;
            commandHintString = '';
            combineStrings(false);
            appendInteractiveText();
            outputString = '';
            if (length(cState.input.text) > 0) waitForCommandExecution();
            cHistory.pop();
            cHistory.push(stringifyState());
            cHistory.push('');
            mHistory = cHistory.copy();
            mHistIndex = cHistory.length - 1;
            cState = blankState();
        }
    }

    inline function handleTab():Void {
        if (cState.hints != null && cState.hints.length > 0) {
            currentToken.text = cState.hints[0].text;
            validateState(true);
            if (cState.completeError == null) {
                currentToken.next = blankToken(currentToken);
                currentToken = currentToken.next;
                caretIndex = 0;
            } else {
                caretIndex = length(currentToken.text);
            }
        } else if (length(currentToken.text) == 0) {
            validateState(false);
        }
    }

    inline function handleEscape():Void {
        cState = blankState();
        validateState(false);
    }

    inline function handleCaretLeft(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (currentToken.prev != null) currentToken = currentToken.prev;
            caretIndex = length(currentToken.text);
        } else if (alt) {
            if (currentToken.prev != null) currentToken = currentToken.prev;
            caretIndex = length(currentToken.text);
        } else {
            if (caretIndex == 0) {
                if (currentToken.prev != null) {
                    currentToken = currentToken.prev;
                    caretIndex = length(currentToken.text);
                }
            } else {
                caretIndex--;
            }
        }
    }

    inline function handleCaretRight(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            while (currentToken.next != null) currentToken = currentToken.next;
            caretIndex = length(currentToken.text);
        } else if (alt) {
            if (currentToken.next != null) currentToken = currentToken.next;
            caretIndex = length(currentToken.text);
        } else {
            if (caretIndex == length(currentToken.text)) {
                if (currentToken.next != null) {
                    currentToken = currentToken.next;
                    caretIndex = 0;
                }
            } else {
                caretIndex++;
            }
        }
    }

    inline function handleUp():Void {
        if (mHistIndex > 0) {
            mHistory[mHistIndex] = stringifyState();
            mHistIndex--;
            loadStateFromString(mHistory[mHistIndex]);
            validateState(true);
        }
    }

    inline function handleDown():Void {
        if (mHistIndex < mHistory.length - 1) {
            mHistory[mHistIndex] = stringifyState();
            mHistIndex++;
            loadStateFromString(mHistory[mHistIndex]);
            validateState(true);
        }
    }

    inline function handleChar(charCode:Int):Void {
        if (charCode > 0) {
            var char:String = String.fromCharCode(charCode);
            var left:String = sub(currentToken.text, 0, caretIndex);
            var right:String = sub(currentToken.text, caretIndex);
            var token:ConsoleToken = currentToken;
            if (char == ' ' && token.type != Tail) {
                if (length(right) == 0) {
                    trimState();
                    if (length(token.text) == 0) {
                        validateState(false);
                    } else {
                        validateState(true);
                        if (cState.completeError == null) {
                            token.text = left;
                            token.next = blankToken(token);
                            token = token.next;
                            currentToken = token;
                            caretIndex = 0;
                        }
                    }
                }
            } else {
                var restriction:String = null;
                if (token.prev != null && token.prev.type == Key) restriction = cState.currentCommand.keys[token.prev.text];
                if (restriction == null || restriction.indexOf(char) != -1) {
                    if (token.next != null || cState.hintError == null) {
                        trimState();
                        token.text = left + char + right;
                        caretIndex++;
                        validateState(false);
                    }
                }
            }
        }
    }

    inline function trimState():Void {
        var token:ConsoleToken = currentToken;

        while (token != null) {
            if (token.type != null) {
                switch (token.type) {
                    case Key: if (cState.keyReg[token.text] == true) cState.keyReg[token.text] = false;
                    case Flag: if (cState.flagReg[token.text] == true) cState.flagReg[token.text] = false;
                    case TailMarker: cState.tailMarkerPresent = false;
                    case _:
                }
                token.type = null;
            }
            token = token.next;
        }

        currentToken.next = null;
    }

    function appendInteractiveText():Void console.addToText(combinedString);
    function printInteractiveText():Void console.setInteractiveText(combinedString);

    function combineStrings(includeCaret:Bool = true):Void {
        combinedString = outputString;

        if (iState == Executing) {
            combinedString += '  ' + Strings.WAIT_INDICATOR;
        } else {
            var hintString:String = '';
            if (cState.finalError != null) hintString = '  §{${Strings.ERROR_OUTPUT_STYLENAME}}${cState.finalError}§{}';
            else if (cState.completeError != null) hintString = '  §{${Strings.ERROR_OUTPUT_STYLENAME}}${cState.completeError}§{}';
            else if (cState.hintError != null) hintString = '  §{${Strings.ERROR_OUTPUT_STYLENAME}}${cState.hintError}§{}';
            else hintString = printHints(cState.hints);

            var inputString:String = printTokens(cState.input, includeCaret);

            combinedString += prompt + inputString + '\n';
            if (length(hintString) > 0) combinedString += hintString + '\n';
            if (length(commandHintString) > 0) combinedString += '   ---\n' + commandHintString + '\n';
        }
    }

    function handleMouseInteraction(id:String, type:MouseInteractionType):Void {
        if (iState == Idle) {
            switch (type) {
                case ENTER:
                    if (hintsByID[id] != null && cState.currentCommand != null) {
                        bakeArgs();
                        cState.currentCommand.hintRollOver(cState.args, hintsByID[id]);
                    }
                case EXIT:
                    if (hintsByID[id] != null && cState.currentCommand != null) {
                        cState.currentCommand.hintRollOut();
                    }
                case CLICK:
                    if (tokensByID[id] != null) {
                        currentToken = tokensByID[id];
                        caretIndex = length(currentToken.text);
                    } else if (hintsByID[id] != null) {
                        currentToken.text = hintsByID[id].text;
                        validateState(true);
                        if (cState.completeError == null) {
                            hintsByID = new Map();
                            tokensByID = new Map();
                            currentToken.next = blankToken(currentToken);
                            currentToken = currentToken.next;
                            caretIndex = 0;
                        } else {
                            caretIndex = length(currentToken.text);
                        }
                    }
                    combineStrings();
                    printInteractiveText();
                case _:
            }
        }
    }

    function validateState(isComplete:Bool, isFinal:Bool = false):Void {
        var completeError:String = null;
        var finalError:String = null;
        var hintError:String = null;
        var type:ConsoleTokenType = null;
        var token:ConsoleToken = currentToken;
        var prev:ConsoleToken = token.prev;
        var currentText:String = token.text;
        var hints:Array<ConsoleToken> = null;

        if (prev == null) {
            type = CommandName;
            if (isComplete && length(currentText) > 0) {
                if (commands[currentText] == null) {
                    completeError = 'Command not found.';
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
                if (hints.empty()) {
                    if (length(currentText) > 0) hintError = 'No matches found.';
                } else {
                    hints.sort(alphabeticallyByName);
                }
            }
        } else {
            switch (prev.type) {
                case Key:
                    type = Value;
                    token.type = type;
                    if (isComplete && length(currentText) == 0) {
                        completeError = 'Empty value.';
                    }
                    if (isFinal && length(currentText) == 0) {
                        finalError = 'Missing value.';
                    }
                case TailMarker:
                    type = Tail;
                    token.type = type;
                    if (isFinal && length(currentText) == 0) {
                        finalError = 'Missing tail.';
                    }
                case _:
                    if (!cState.autoTail && !cState.tailMarkerPresent && currentText == ':') {
                        type = TailMarker;
                        if (isComplete) cState.tailMarkerPresent = true;
                    } else {
                        if (isComplete) {
                            if (isFinal && length(currentText) == 0) {

                            } else if (isFinal && cState.keyReg[currentText] != null) {
                                finalError = 'Missing value.';
                            } else if (cState.keyReg[currentText] == false) {
                                type = Key;
                                cState.keyReg[currentText] = true;
                            } else if (cState.keyReg[currentText] == true) {
                                completeError = 'Duplicate key.';
                            } else if (cState.flagReg[currentText] == false) {
                                type = Flag;
                                cState.flagReg[currentText] = true;
                            } else if (cState.flagReg[currentText] == true) {
                                completeError = 'Duplicate flag.';
                            } else {
                                completeError = 'No matches found.';
                            }
                        } else {
                            var keys = cState.keyReg.keys().intoArray().filter(isUnusedMatch.bind(_, cState.keyReg, currentText));
                            var keyHints:Array<ConsoleToken> = keys.map(argToHint.bind(_, Key));

                            var flags = cState.flagReg.keys().intoArray().filter(isUnusedMatch.bind(_, cState.flagReg, currentText));
                            var flagHints:Array<ConsoleToken> = flags.map(argToHint.bind(_, Flag));

                            if (keyHints.empty() && flagHints.empty()) {
                                if (length(currentText) > 0) hintError = 'No matches found.';
                            } else {
                                hints = keyHints.concat(flagHints);
                                hints.sort(alphabeticallyByName);
                            }
                        }
                    }
            }
        }

        if (isComplete) token.type = type;
        // trace(type);

        cState.completeError = completeError;
        cState.finalError = finalError;
        cState.hintError = hintError;
        cState.hints = hints;
    }

    function startsWith(arg:String, sub:String):Bool return arg.indexOf(sub) == 0;

    function isUnusedMatch(arg:String, argMap:Map<String, Bool>, sub:String):Bool {
        return !argMap[arg] && arg.indexOf(sub) == 0;
    }

    function argToHint(arg:String, type:ConsoleTokenType):ConsoleToken return {text:arg, type:type};

    function alphabeticallyByName(hint1:ConsoleToken, hint2:ConsoleToken):Int {
        if (hint1.text == hint2.text) return 0;
        else if (hint1.text > hint2.text) return 1;
        else return -1;
    }

    inline function bakeArgs():Void {
        if (cState.currentCommand != null && cState.args == null) {
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

    inline function printTokens(token:ConsoleToken, includeCaret:Bool):String {
        var index:Int = 0;
        var str:String = '';
        while (token != null) {
            str += styleToken(token, includeCaret, index);
            if (token.next != null) str += ' ';
            index++;
            token = token.next;
        }
        return str;
    }

    inline function printHints(hints:Array<ConsoleToken>):String {
        var hintStrings:Array<String> = [];
        if (hints != null) {
            for (hint in hints) {
                var styleName:String = Strings.INPUT_STYLENAME;
                if (hint.type != null) styleName = styleNamesByType[hint.type];
                var id:String = hint.text;
                if (id == ':') id = '__tailmarker';
                hintsByID[id] = hint;
                hintStrings.push('  §{name:$styleName, id:$id}${hint.text}§{}');
            }
        }
        return hintStrings.join('\n');
    }

    inline function styleToken(token:ConsoleToken, includeCaret:Bool, index:Int):String {
        var str:String = token.text;
        var styleName:String = Strings.INPUT_STYLENAME;
        if (token == currentToken && includeCaret) {
            str = sub(str, 0, caretIndex) + CARET + sub(str, caretIndex);
        }
        if (token.next == null && (cState.completeError != null || cState.hintError != null)) {
            styleName = Strings.ERROR_INPUT_STYLENAME;
        } else if (token.type != null) {
            styleName = styleNamesByType[token.type];
        }
        var id:String = '__$index';
        tokensByID[id] = token;
        return '§{name:$styleName, id:$id}$str§{}';
    }

    inline function checkForCommandHintCondition():Void {
        var shouldWait:Bool = false;
        if (iState == Idle && cState.currentCommand != null) {
            var lastToken:ConsoleToken = cState.input;
            while (lastToken.next != null) lastToken = lastToken.next;
            var tokenIsEmpty:Bool = length(lastToken.text) == 0;
            var prev:ConsoleToken = lastToken.prev;

            if (lastToken.type == Value && !tokenIsEmpty) {
                shouldWait = true;
            } else if (tokenIsEmpty && prev != null && (prev.type == Flag || prev.type == Value)) {
                shouldWait = true;
            }
        }

        if (shouldWait) waitForCommandHints();
        else commandHintString = '';
    }

    function waitForCommandHints():Void {
        cState.args = null;
        bakeArgs();
        console.freeze();
        iState = Hinting;
        cState.currentCommand.hintSignal.add(onCommandHint);
        Timer.delay(function() cState.currentCommand.hint(cState.args), 0);
    }

    function onCommandHint(str:String, hints:Array<ConsoleToken>):Void {
        commandHintString = '  §{${Strings.COMMAND_HINT_STYLENAME}}$str§{}';

        if (hints != null && hints.length > 0) commandHintString += '\n' + printHints(hints);

        cState.currentCommand.hintSignal.remove(onCommandHint);
        iState = Idle;
        console.unfreeze();
        combineStrings();
        printInteractiveText();
    }

    function waitForCommandExecution():Void {
        cState.args = null;
        bakeArgs();
        console.freeze();
        iState = Executing;
        runningCommand = cState.currentCommand;
        runningCommand.outputSignal.add(onCommandExecute);
        var args:ConsoleCommandArgs = cState.args;
        Timer.delay(function() runningCommand.execute(args), 0);
    }

    function onCommandExecute(str:String, done:Bool):Void {
        if (done) {
            runningCommand.outputSignal.remove(onCommandExecute);
            runningCommand = null;
            console.unfreeze();
            iState = Idle;
        }
        outputString += '  ' + str + '\n';
        combineStrings();
        printInteractiveText();
    }

    inline function stringifyState():String {
        var tokenStrings:Array<String> = [];
        var token:ConsoleToken = cState.input;
        while (token != null) {
            if (length(token.text) > 0) tokenStrings.push(token.text);
            token = token.next;
        }
        return tokenStrings.join(' ');
    }

    inline function loadStateFromString(str:String):Void {
        cState = blankState();
        Utf8.iter(str, handleChar);
    }

    inline function get_currentToken():ConsoleToken return cState.currentToken;
    inline function set_currentToken(val:ConsoleToken):ConsoleToken return cState.currentToken = val;

    inline function get_caretIndex():Int return cState.caretIndex;
    inline function set_caretIndex(val:Int):Int return cState.caretIndex = val;

    static function makeStyleNamesByType():Map<ConsoleTokenType, String> {
        var styleNamesByType:Map<ConsoleTokenType, String> = new Map();
        styleNamesByType[Key] = Strings.KEY_STYLENAME;
        styleNamesByType[Value] = Strings.VALUE_STYLENAME;
        styleNamesByType[Flag] = Strings.FLAG_STYLENAME;
        styleNamesByType[CommandName] = Strings.COMMAND_NAME_STYLENAME;
        styleNamesByType[Tail] = Strings.TAIL_STYLENAME;
        styleNamesByType[TailMarker] = Strings.TAIL_MARKER_STYLENAME;
        return styleNamesByType;
    }

    inline static function blankState():ConsoleState {
        var tok = blankToken();
        return {input:tok, output:null, hint:null, currentToken:tok, caretIndex:0};
    }

    inline static function blankToken(prev:ConsoleToken = null, next:ConsoleToken = null):ConsoleToken {
        return {text:'', type:null, prev:prev, next:next};
    }
}
