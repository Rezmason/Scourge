package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;

import haxe.Timer;
import haxe.Utf8;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;
using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.ArrayUtils;

/**
 * An Interpreter sits atop a ConsoleUIMediator, interpreting interactions of that mediator and populating it with text.
 * Whereas a ConsoleUIMediator operates on spans of text, an Interpreter operates on tokens.
 * Tokens have types, and the validity of a token depends on type, token order and argument availability.
 * Arguments are derived from the properties of ConsoleCommands, which are subscribed to the Interpreter.
 * This is the second role of an Interpreter - to send arguments to ConsoleCommands, and to interpret their output while
 * waiting for them to complete.
 *
 * Interpreters are meant to behave like terminal emulators with syntax highlighting and text completion.
 * That includes a history of previously entered commands. Consequently, much of an Interpreter's state is
 * kept in a memento stored in its history.
 */

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

    /**
     * If two human players are taking turns playing on one computer, this prompt will serve to indicate
     * to them whose turn it is.
     */
    public function setPrompt(name:String, color:Int):Void {

        var r:Float = (color >> 16 & 0xFF) / 0xFF;
        var g:Float = (color >> 8  & 0xFF) / 0xFF;
        var b:Float = (color >> 0  & 0xFF) / 0xFF;

        prompt =
        '∂{name:head_prompt_${name}_${Math.random()}, basis:${Strings.BREATHING_PROMPT_STYLENAME}, r:$r, g:$g, b:$b}Ω' +
        '§{name:prompt_${name}_${Math.random()}, r:$r, g:$g, b:$b} $name§{}${Strings.PROMPT}§{}';
    }

    /**
     * Sort of the "entry point". The majority of the work starts here.
     */
    function handleKeyboard(key:Int, charCode:Int, alt:Bool, ctrl:Bool):Void {

        clearInteractiveTokens();

        switch (key) {
            case Keyboard.BACKSPACE: handleBackspace(alt, ctrl);
            case Keyboard.ENTER: handleEnter();
            case Keyboard.ESCAPE: handleEscape();
            case Keyboard.LEFT: handleCaretLeft(alt, ctrl);
            case Keyboard.RIGHT: handleCaretRight(alt, ctrl);
            case Keyboard.UP: handleUp();
            case Keyboard.DOWN: handleDown();
            case Keyboard.TAB: handleTab();
            case _:
                if (charCode > 0) {
                    if (ctrl) handleHotKey(charCode, alt);
                    else handleChar(charCode);
                }
        }

        if (key != Keyboard.LEFT && key != Keyboard.RIGHT) checkForCommandHintCondition();
        else commandHintString = '';

        combineStrings();
        printInteractiveText();
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        if (!alt && !ctrl) {
            if (caretIndex != 0) {
                // Delete one character.
                var left:String = sub(currentToken.text, 0, caretIndex);
                var right:String = sub(currentToken.text, caretIndex);
                trimState();
                currentToken.text = sub(left, 0, length(left) - 1) + right;
                caretIndex--;
                validateState(false);
            } else if (length(currentToken.text) == 0 && currentToken.prev != null) {
                alt = true;
            }
        }
        if (alt && !ctrl) {
            // Clear the current token and all subsequent tokens, and move the caret to the last token.
            if (currentToken.prev != null) {
                currentToken = currentToken.prev;
                caretIndex = length(currentToken.text);
                trimState();
                validateState(false);
            } else {
                ctrl = true;
            }
        }
        if (ctrl) {
            // Delete the whole thing.
            cState = blankState();
        }
    }

    inline function handleEnter():Void {
        validateState(true, true);
        if (cState.completeError == null && cState.finalError == null) {
            // Flush the hint stuff from the state. That stuff doesn't belong in the history.
            cState.hints = null;
            cState.commandHints = null;
            commandHintString = '';
            // Add the old output and current input to the log.
            combineStrings(false);
            appendInteractiveText();
            outputString = '';
            // Call the command.
            if (length(cState.input.text) > 0) waitForCommandExecution();
            // Append the state to the history, and make a new state.
            var stateString:String = stringifyState();
            if (length(stateString) > 0 && (cHistory.length <= 1 || cHistory[cHistory.length - 2] != stateString)) {
                cHistory.pop();
                cHistory.push(stateString);
                cHistory.push('');
            }
            mHistory = cHistory.copy();
            mHistIndex = cHistory.length - 1;
            cState = blankState();
        }
    }

    inline function handleTab():Void autoComplete();

    inline function handleEscape():Void {
        cState = blankState();
        validateState(false);
    }

    inline function handleCaretLeft(alt:Bool, ctrl:Bool):Void {
        if (ctrl) {
            // Move the caret to the end of the first token.
            currentToken = cState.input;
            caretIndex = length(currentToken.text);
        } else if (alt) {
            // Move the caret to the end of the previous token.
            if (currentToken.prev != null) currentToken = currentToken.prev;
            caretIndex = length(currentToken.text);
        } else {
            // Move the caret left, or to the end of the previous token.
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
            // Move the caret to the end of the last token.
            while (currentToken.next != null) currentToken = currentToken.next;
            caretIndex = length(currentToken.text);
        } else if (alt) {
            // Move the caret to the end of the next token.
            if (currentToken.next != null) currentToken = currentToken.next;
            caretIndex = length(currentToken.text);
        } else {
            // Move the caret right, or to the start of the next token.
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

        // A quick note about history.
        // Most Unix shells have a history that is immutable that's behind the scenes,
        // and is cloned into a mutable history. Users can mess with the whole mutable history,
        // but as soon as they execute a command, that history is replaced with a fresh clone
        // of the immutable one. Interpreters behave the same way.

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

    inline function handleHotKey(charCode:Int, alt:Bool):Void {
        var char:String = String.fromCharCode(charCode);
        if (ConsoleRestriction.INTEGERS.indexOf(char) != -1) adoptHintAtIndex(Std.parseInt(char));
        // else if (char == 'k') console.clearText();
        else if (char == ' ') autoComplete();
    }

    inline function handleChar(charCode:Int):Void {
        var char:String = String.fromCharCode(charCode);
        var left:String = sub(currentToken.text, 0, caretIndex);
        var right:String = sub(currentToken.text, caretIndex);
        var token:ConsoleToken = currentToken;
        if (char == ' ' && token.type != Tail) {
            if (length(right) == 0) {
                // Complete the current token and append the next one.
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
            // Add a character to the current token, if it's allowed.
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

    /**
     * Whenever the state changes, the current token should be the LAST token. Any tokens to its right
     * ought to be destroyed, and if they are keys, flags or tail markers, then those args need to be
     * freed from the registry.
     */
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

    /**
     * Combines input, output, errors, hints and command hints into a single string to send to the console.
     */
    function combineStrings(includeCaret:Bool = true):Void {
        combinedString = outputString;

        if (iState == Executing) {
            combinedString += '  ' + Strings.WAIT_INDICATOR;
        } else {
            var hintString:String = '';
            if (cState.finalError != null) hintString = '  ' + styleError(cState.finalError);
            else if (cState.completeError != null) hintString = '  ' + styleError(cState.completeError);
            else if (cState.hintError != null) hintString = '  ' + styleError(cState.hintError);
            else hintString = printHints(cState.hints);

            var inputString:String = printTokens(cState.input, includeCaret);

            combinedString += prompt + inputString + '\n';
            if (length(hintString) > 0) combinedString += hintString + '\n';
            if (length(commandHintString) > 0) {
                if (length(hintString) > 0) combinedString += '\n';
                combinedString += commandHintString + '\n';
            }
        }
    }

    /**
     * Another "entry point". Hover events are forwarded to the current command.
     * Click events are resolved to either a token or a hint.
     */
    function handleMouseInteraction(id:String, type:MouseInteractionType):Void {
        if (iState == Idle) {
            switch (type) {
                case ENTER:
                    if (hintsByID[id] != null && cState.currentCommand != null) {
                        bakeArgs(false);
                        cState.currentCommand.hintRollOver(cState.args, hintsByID[id]);
                    }
                case EXIT:
                    if (hintsByID[id] != null && cState.currentCommand != null) {
                        cState.currentCommand.hintRollOut();
                    }
                case CLICK:
                    if (tokensByID[id] != null) {
                        // Clicking a token sets it to the current token.
                        currentToken = tokensByID[id];
                        caretIndex = length(currentToken.text);
                    } else if (hintsByID[id] != null) {
                        // Clicking a hint assigns the text of the hint to the current token.
                        adoptHint(hintsByID[id]);
                    }
                    checkForCommandHintCondition();
                    combineStrings();
                    printInteractiveText();
                case _:
            }
        }
    }

    /**
     * The tables used to resolve span IDs to tokens must be cleared whenever the state's text changes.
     */
    function clearInteractiveTokens():Void {
        tokensByID = new Map();
        hintsByID = new Map();
    }

    /**
     * This validation function is sprawling, but straightforward.
     */
    function validateState(isComplete:Bool, isFinal:Bool = false):Void {
        var completeError:String = null;
        var finalError:String = null;
        var hintError:String = null;
        var type:ConsoleTokenType = null;
        var token:ConsoleToken = currentToken;
        var currentText:String = token.text;
        var hints:Array<ConsoleToken> = null;

        if (token == cState.input) {
            // The first token is always a command name.
            type = CommandName;
            if (isComplete && length(currentText) > 0) {
                if (commands[currentText] == null) {
                    completeError = 'Command not found.';
                } else {

                    // Resolve the named command to the current command.
                    // Populate the state's key, flag and tail marker registries.

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

                // Produce hints for command names.

                hints = commands.keys().intoArray().filter(startsWith.bind(_, currentText)).map(argToHint.bind(_, CommandName));
                if (hints.empty()) {
                    if (length(currentText) > 0) hintError = 'No matches found.';
                } else {
                    hints.sort(alphabeticallyByName);
                }
            }
        } else {
            var prev:ConsoleToken = token.prev;
            switch (prev.type) {
                case Key:
                    // Keys are always followed by values; therefore, this token is a value.
                    type = Value;
                    token.type = type;
                    if (isComplete && length(currentText) == 0) {
                        completeError = 'Empty value.';
                    }
                    // The state isn't final unless every key has a matching complete value.
                    if (isFinal && length(currentText) == 0) {
                        finalError = 'Missing value.';
                    }
                case TailMarker:
                    // A tail marker is always followed by a tail; therefore, this token is a tail.
                    type = Tail;
                    token.type = type;
                    // The state isn't final unless every tail marker has a matching complete tail.
                    if (isFinal && length(currentText) == 0) {
                        finalError = 'Missing tail.';
                    }
                case _:
                    if (cState.autoTail) {
                        // Auto tail, for simple commands.
                        type = Tail;
                        token.type = type;
                    } else if (!cState.tailMarkerPresent && currentText == ':') {
                        // There can only be one tail marker, and it's denoted by a single ':' character.
                        type = TailMarker;
                        if (isComplete) cState.tailMarkerPresent = true;
                    } else {
                        if (isComplete) {
                            if (isFinal && length(currentText) == 0) {
                                // Empty final tokens are ignored when finalizing the state.
                            } else if (isFinal && cState.keyReg[currentText] != null) {
                                // This is a key without a value.
                                finalError = 'Missing value.';
                            } else if (cState.keyReg[currentText] == false) {
                                // Complete the key token and mark the key as in use.
                                type = Key;
                                cState.keyReg[currentText] = true;
                            } else if (cState.keyReg[currentText] == true) {
                                // Can't use the same key twice.
                                completeError = 'Duplicate key.';
                            } else if (cState.flagReg[currentText] == false) {
                                // Complete the flag token and mark the flag as in use.
                                type = Flag;
                                cState.flagReg[currentText] = true;
                            } else if (cState.flagReg[currentText] == true) {
                                // Can't use the same flag twice.
                                completeError = 'Duplicate flag.';
                            } else {
                                // There's no key or flag that starts with the current token's text.
                                completeError = 'No matches found.';
                            }
                        } else {
                            hints = makeKeyFlagHints(currentText);
                            if (hints.empty()) {
                                if (length(currentText) > 0) hintError = 'No matches found.';
                                hints = null;
                            }
                        }
                    }
            }
        }

        // Copy results to the state.
        if (isComplete) {
            token.type = type;
            if (completeError == null && !isFinal && (type == Value || type == Flag)) hints = makeKeyFlagHints('');
        }
        cState.completeError = completeError;
        cState.finalError = finalError;
        cState.hintError = hintError;
        cState.hints = hints;
    }

    /**
     * All unused keys and flags that match the input text are made into hints and returned in an array.
     */
    function makeKeyFlagHints(text:String):Array<ConsoleToken> {
        var keys = cState.keyReg.keys().intoArray().filter(isUnusedMatch.bind(_, cState.keyReg, text));
        var flags = cState.flagReg.keys().intoArray().filter(isUnusedMatch.bind(_, cState.flagReg, text));

        var keyHints:Array<ConsoleToken> = keys.map(argToHint.bind(_, Key));
        var flagHints:Array<ConsoleToken> = flags.map(argToHint.bind(_, Flag));

        var hints:Array<ConsoleToken> = keyHints.concat(flagHints);
        hints.sort(alphabeticallyByName);
        return hints;
    }

    function isUnusedMatch(arg:String, argMap:Map<String, Bool>, sub:String):Bool {
        return !argMap[arg] && arg.indexOf(sub) == 0;
    }

    function alphabeticallyByName(hint1:ConsoleToken, hint2:ConsoleToken):Int {
        if (hint1.text == hint2.text) return 0;
        else if (hint1.text > hint2.text) return 1;
        else return -1;
    }

    inline function autoComplete():Void {
        if (!adoptHintAtIndex(0) && length(currentToken.text) == 0) {
            // Spit out whatever hints are available.
            validateState(false);
        }
    }

    inline function adoptHintAtIndex(index:Int):Bool {
        var hint:ConsoleToken = null;
        if (cState.hints != null && cState.hints.length > index) {
            hint = cState.hints[index];
        } else if (cState.commandHints != null && cState.commandHints.length > index) {
            if (cState.hints != null) index -= cState.hints.length;
            hint = cState.commandHints[index];
        }

        if (hint != null) adoptHint(hint);
        return hint != null;
    }

    inline function adoptHint(hint:ConsoleToken):Void {
        // Complete the current token with the text in the provided hint.
        currentToken.text = hint.text;
        validateState(true);
        if (cState.completeError == null) {
            clearInteractiveTokens();
            currentToken.next = blankToken(currentToken);
            currentToken = currentToken.next;
            caretIndex = 0;
        } else {
            caretIndex = length(currentToken.text);
        }
    }

    /**
     * Commands have no need for tokens; the interpreter sends them a ConsoleCommandArgs object.
     */
    inline function bakeArgs(isFinal:Bool):Void {
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
                            if (token.next == currentToken) {
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
            if (isFinal) {
                cState.args.keyValuePairs[pendingKey] = pendingValue;
            } else {
                cState.args.pendingKey = pendingKey;
                cState.args.pendingValue = pendingValue;
            }
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

    /**
     * Converts a token to styled text. Optionally includes the caret.
     */
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

    inline function printHints(hints:Array<ConsoleToken>):String {
        var hintStrings:Array<String> = [];
        if (hints != null) hintStrings = hints.map(styleHint);
        return hintStrings.join('\n');
    }

    /**
     * Converts a hint to styled text.
     */
     inline function styleHint(hint:ConsoleToken):String {
        var styleName:String = Strings.INPUT_STYLENAME;
        if (hint.type != null) styleName = styleNamesByType[hint.type];
        var id:String = hint.text;
        hintsByID[id] = hint;
        return '  §{name:$styleName, id:$id}${hint.text}§{}';
    }

    /**
     * If an Interpreter is idle and has a command, it may poll the command for command-specific hints.
     */
    inline function checkForCommandHintCondition():Void {
        var shouldWait:Bool = false;
        if (iState == Idle && cState.currentCommand != null) {
            var lastToken:ConsoleToken = cState.input;
            while (lastToken.next != null) lastToken = lastToken.next;
            shouldWait = lastToken.type == Value || (lastToken.prev != null && lastToken.prev.type == Key);
        }

        if (shouldWait) waitForCommandHints();
        else commandHintString = '';
    }

    /**
     * Freezes the console, sends args to the command and awaits a hint response.
     */
    function waitForCommandHints():Void {
        cState.args = null;
        bakeArgs(false);
        console.freeze();
        iState = Hinting;
        cState.currentCommand.hintSignal.add(onCommandHint);
        Timer.delay(function() cState.currentCommand.hint(cState.args), 0);
    }

    /**
     * Unfreezes the console and processes the command hints.
     */
    function onCommandHint(str:String, commandHints:Array<ConsoleToken>):Void {
        cState.commandHints = commandHints;

        var commandHintStrings:Array<String> = [];
        if (str != null) commandHintStrings.push('  §{${Strings.COMMAND_HINT_STYLENAME}}$str§{}');
        if (commandHints != null && commandHints.length > 0) commandHintStrings.push(printHints(commandHints));
        commandHintString = commandHintStrings.join('\n');

        cState.currentCommand.hintSignal.remove(onCommandHint);
        iState = Idle;
        console.unfreeze();
        combineStrings();
        printInteractiveText();
    }

    /**
     * Freezes the console, sends args to the command and awaits an execution response.
     */
    function waitForCommandExecution():Void {
        cState.args = null;
        bakeArgs(true);
        console.freeze();
        iState = Executing;
        runningCommand = cState.currentCommand;
        runningCommand.outputSignal.add(onCommandExecute);
        var args:ConsoleCommandArgs = cState.args;
        Timer.delay(function() runningCommand.execute(args), 0);
    }

    /**
     * Appends the output, and, if the command has finished, unfreezes the console.
     */
    function onCommandExecute(str:String, done:Bool):Void {
        if (done) {
            runningCommand.outputSignal.remove(onCommandExecute);
            runningCommand = null;
            console.unfreeze();
            iState = Idle;
        }
        if (str != null) outputString += '  ' + str + '\n';
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

    // shortcut to cState.currentToken
    inline function get_currentToken():ConsoleToken return cState.currentToken;
    inline function set_currentToken(val:ConsoleToken):ConsoleToken return cState.currentToken = val;

    // shortcut to cState.caretIndex
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
}
