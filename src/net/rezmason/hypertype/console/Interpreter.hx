package net.rezmason.hypertype.console;

import haxe.Timer;
import haxe.Utf8;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import net.rezmason.math.Vec3;
import net.rezmason.hypertype.console.ConsoleTypes;
import net.rezmason.hypertype.console.ConsoleUtils.*;
import net.rezmason.hypertype.core.MouseInteractionType;
import net.rezmason.hypertype.text.Sigil.*;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;
using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.CharCode;

/**
 * An Interpreter sits atop a ConsoleUIMediator, interpreting interactions of that mediator and populating it with text.
 * Whereas a ConsoleUIMediator operates on spans of text, an Interpreter operates on tokens.
 * Tokens have types, and the validity of a token depends on type, token order and argument availability.
 * Arguments are derived from the properties of UserActions, which are subscribed to the Interpreter.
 * This is the second role of an Interpreter - to send arguments to UserActions, and to interpret their output while
 * waiting for them to complete.
 *
 * Interpreters are meant to behave like terminal emulators with syntax highlighting and text completion.
 * That includes a history of previously entered actions. Consequently, much of an Interpreter's state is
 * kept in a memento stored in its history.
 */

class Interpreter {

    static var US_KEYBOARD = "                                 !\"#$%&\"()*+<_>?)!@#$%^&*(::<+>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}^_~ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~";
    static var styleNamesByType:Map<ConsoleTokenType, String> = makeStyleNamesByType();

    var currentToken(get, set):ConsoleToken;
    var caretIndex(get, set):Int;

    var console:ConsoleUIMediator;
    var cState:ConsoleState;
    var iState:InterpreterState;
    var actions:Map<String, UserAction>;
    var runningAction:UserAction;
    var prompt:String;
    var actionHintString:String;
    var outputString:String;
    var combinedString:String;
    var cHistory:Array<String>;
    var mHistory:Array<String>;
    var mHistIndex:Int = 0;

    var tokensByID:Map<String, ConsoleToken>;
    var hintsByID:Map<String, ConsoleToken>;

    public function new(console:ConsoleUIMediator):Void {
        setPrompt('user', Vec3.fromHex(0x3060FF));
        this.console = console;
        this.console.keyboardSignal.add(handleKeyboard);
        this.console.mouseSignal.add(handleMouseInteraction);
        cState = blankState();
        cHistory = [''];
        mHistory = cHistory.copy();
        mHistIndex = 0;

        iState = Idle;
        actions = new Map();
        runningAction = null;

        console.loadStyles([
            ConsoleStrings.BREATHING_PROMPT_STYLE,
            ConsoleStrings.WAIT_STYLES,
            ConsoleStrings.ACTION_HINT_STYLE,
            ConsoleStrings.INPUT_STYLE,
            ConsoleStrings.ERROR_STYLES,
            ConsoleStrings.INTERPRETER_STYLES,
        ].join(''));

        actionHintString = '';
        outputString = '';

        tokensByID = new Map();
        hintsByID = new Map();
        combineStrings();
        printInteractiveText();
    }

    public function addAction(action:UserAction):Void {
        if (action != null) {
            if (actions[action.name] != null && actions[action.name] != action) {
                throw 'Existing action with name ${action.name}';
            }
            actions[action.name] = action;
        }
    }

    public function removeAction(action:UserAction):Void {
        actions.remove(action.name);
    }

    /**
     * If two human players are taking turns playing on one computer, this prompt will serve to indicate
     * to them whose turn it is.
     */
    public function setPrompt(name:String, color:Vec3):Void {
        var r:Float = color.r;
        var g:Float = color.g;
        var b:Float = color.b;
        prompt =
        '∂{name:head_prompt_${name}_${Math.random()}, basis:${ConsoleStrings.BREATHING_PROMPT_STYLENAME}, r:$r, g:$g, b:$b}Ω' +
        '§{name:prompt_${name}_${Math.random()}, r:$r, g:$g, b:$b} $name§{}${ConsoleStrings.PROMPT}§{}';
    }

    /**
     * Sort of the "entry point". The majority of the work starts here.
     */
    function handleKeyboard(keyCode:KeyCode, modifier:KeyModifier):Void {

        clearInteractiveTokens();

        switch (keyCode) {
            case BACKSPACE: handleBackspace(modifier.altKey, modifier.ctrlKey);
            case RETURN: handleEnter();
            case ESCAPE: handleEscape();
            case LEFT: handleCaretLeft(modifier.altKey, modifier.ctrlKey);
            case RIGHT: handleCaretRight(modifier.altKey, modifier.ctrlKey);
            case UP: handleUp();
            case DOWN: handleDown();
            case TAB: handleTab();
            case _:
                if (keyCode != UNKNOWN) {
                    if (modifier.ctrlKey) handleHotKey(keyCode, modifier.altKey);
                    else handleChar(keyCode, modifier.shiftKey);
                }
        }

        if (keyCode != LEFT && keyCode != RIGHT) checkForActionHintCondition();
        else actionHintString = '';

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
            cState.actionHints = null;
            actionHintString = '';
            // Add the old output and current input to the log.
            combineStrings(false);
            appendInteractiveText();
            outputString = '';
            // Call the action.
            if (length(cState.input.text) > 0) waitForActionExecution();
            // Append the state to the history, and make a new state.
            var stateString:String = stringifyState();
            if (length(stateString) > 0 && (cHistory.length <= 1 || cHistory[cHistory.length - 2] != stateString)) {
                cHistory.pop();
                var tokenType:ConsoleTokenType = currentToken.type;
                if (tokenType == ActionName || tokenType == Flag || tokenType == TailMarker) stateString += ' ';
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
        // but as soon as they execute a action, that history is replaced with a fresh clone
        // of the immutable one. Interpreters behave the same way.

        if (mHistIndex > 0) {
            mHistory[mHistIndex] = stringifyState();
            mHistIndex--;
            loadStateFromString(mHistory[mHistIndex]);
        }
    }

    inline function handleDown():Void {
        if (mHistIndex < mHistory.length - 1) {
            mHistory[mHistIndex] = stringifyState();
            mHistIndex++;

            loadStateFromString(mHistory[mHistIndex]);
        }
    }

    inline function handleHotKey(charCode:Int, alt:Bool):Void {
        var char:String = String.fromCharCode(charCode);
        if (ConsoleRestriction.INTEGERS.indexOf(char) != -1) adoptHintAtIndex(Std.parseInt(char));
        // else if (char == 'k') console.clearText();
        else if (char == ' ') autoComplete();
    }

    inline function handleChar(charCode:Int, shiftKey:Bool):Void {
        var char:String = String.fromCharCode(charCode);
        if (shiftKey) char = US_KEYBOARD.charAt(charCode);
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
            if (token.prev != null && token.prev.type == Key) restriction = cState.currentAction.keys[token.prev.text];
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
     * Combines input, output, errors, hints and action hints into a single string to send to the console.
     */
    function combineStrings(includeCaret:Bool = true):Void {
        combinedString = outputString + '¶{}';

        if (iState == Executing) {
            combinedString += '  ' + ConsoleStrings.WAIT_INDICATOR;
        } else {
            var hintString:String = '';
            if (cState.finalError != null) hintString = '  ' + styleError(cState.finalError);
            else if (cState.completeError != null) hintString = '  ' + styleError(cState.completeError);
            else if (cState.hintError != null) hintString = '  ' + styleError(cState.hintError);
            else hintString = printHints(cState.hints);

            var inputString:String = printTokens(cState.input, includeCaret);

            combinedString += prompt + inputString + '\n';
            if (length(hintString) > 0) combinedString += hintString + '\n';
            if (length(actionHintString) > 0) {
                if (length(hintString) > 0) combinedString += '\n';
                combinedString += actionHintString + '\n';
            }
        }
    }

    /**
     * Another "entry point". Hover events are forwarded to the current action.
     * Click events are resolved to either a token or a hint.
     */
    function handleMouseInteraction(id:String, type:MouseInteractionType):Void {
        if (iState == Idle) {
            switch (type) {
                case ENTER:
                    if (hintsByID[id] != null && cState.currentAction != null) {
                        bakeArgs(false);
                        cState.currentAction.hintRollOver(cState.args, hintsByID[id]);
                    }
                case EXIT:
                    if (hintsByID[id] != null && cState.currentAction != null) {
                        cState.currentAction.hintRollOut();
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
                    checkForActionHintCondition();
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
            // The first token is always a action name.
            type = ActionName;
            if (isComplete && length(currentText) > 0) {
                if (actions[currentText] == null) {
                    completeError = 'Action not found.';
                } else {

                    // Resolve the named action to the current action.
                    // Populate the state's key, flag and tail marker registries.

                    var action:UserAction = actions[currentText];
                    cState.currentAction = action;
                    cState.autoTail = action.flags.empty() && action.keys.empty();

                    var keyReg:Map<String, Bool> = new Map();
                    for (key in action.keys.keys()) keyReg[key] = false;
                    cState.keyReg = keyReg;

                    var flagReg:Map<String, Bool> = new Map();
                    for (flag in action.flags) flagReg[flag] = false;
                    cState.flagReg = flagReg;

                    cState.tailMarkerPresent = false;
                }
            } else {

                // Produce hints for action names.

                hints = actions.keys().intoArray().filter(startsWith.bind(_, currentText)).map(argToHint.bind(_, ActionName));
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
                        // Auto tail, for simple actions.
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
        } else if (cState.actionHints != null && cState.actionHints.length > index) {
            if (cState.hints != null) index -= cState.hints.length;
            hint = cState.actionHints[index];
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
     * Actions have no need for tokens; the interpreter sends them a UserActionArgs object.
     */
    inline function bakeArgs(isFinal:Bool):Void {
        if (cState.currentAction != null && cState.args == null) {
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
        var styleName:String = ConsoleStrings.INPUT_STYLENAME;
        if (token == currentToken && includeCaret) {
            str = sub(str, 0, caretIndex) + CARET + sub(str, caretIndex);
        }
        if (token.next == null && (cState.completeError != null || cState.hintError != null)) {
            styleName = ConsoleStrings.ERROR_INPUT_STYLENAME;
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
        var styleName:String = ConsoleStrings.INPUT_STYLENAME;
        if (hint.type != null) styleName = styleNamesByType[hint.type];
        var id:String = hint.text;
        hintsByID[id] = hint;
        return '  §{name:$styleName, id:$id}${hint.text}§{}';
    }

    /**
     * If an Interpreter is idle and has a action, it may poll the action for action-specific hints.
     */
    inline function checkForActionHintCondition():Void {
        var shouldWait:Bool = false;
        if (iState == Idle && cState.currentAction != null) {
            var lastToken:ConsoleToken = cState.input;
            while (lastToken.next != null) lastToken = lastToken.next;
            shouldWait = lastToken.type == Value || (lastToken.prev != null && lastToken.prev.type == Key);
        }

        if (shouldWait) waitForActionHints();
        else actionHintString = '';
    }

    /**
     * Freezes the console, sends args to the action and awaits a hint response.
     */
    function waitForActionHints():Void {
        cState.args = null;
        bakeArgs(false);
        console.freeze();
        iState = Hinting;
        cState.currentAction.hintSignal.add(onActionHint);
        Timer.delay(function() cState.currentAction.hint(cState.args), 0);
    }

    /**
     * Unfreezes the console and processes the action hints.
     */
    function onActionHint(str:String, actionHints:Array<ConsoleToken>):Void {
        cState.actionHints = actionHints;

        var actionHintStrings:Array<String> = [];
        if (str != null) actionHintStrings.push('  §{${ConsoleStrings.ACTION_HINT_STYLENAME}}$str§{}');
        if (actionHints != null && actionHints.length > 0) actionHintStrings.push(printHints(actionHints));
        actionHintString = actionHintStrings.join('\n');

        cState.currentAction.hintSignal.remove(onActionHint);
        iState = Idle;
        console.unfreeze();
        combineStrings();
        printInteractiveText();
    }

    /**
     * Freezes the console, sends args to the action and awaits an execution response.
     */
    function waitForActionExecution():Void {
        cState.args = null;
        bakeArgs(true);
        console.freeze();
        iState = Executing;
        runningAction = cState.currentAction;
        runningAction.outputSignal.add(onActionExecute);
        var args:UserActionArgs = cState.args;
        Timer.delay(function() runningAction.execute(args), 0);
    }

    /**
     * Appends the output, and, if the action has finished, unfreezes the console.
     */
    function onActionExecute(str:String, done:Bool):Void {
        if (done) {
            runningAction.outputSignal.remove(onActionExecute);
            runningAction = null;
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
        Utf8.iter(str, handleChar.bind(_, false));
    }

    // shortcut to cState.currentToken
    inline function get_currentToken():ConsoleToken return cState.currentToken;
    inline function set_currentToken(val:ConsoleToken):ConsoleToken return cState.currentToken = val;

    // shortcut to cState.caretIndex
    inline function get_caretIndex():Int return cState.caretIndex;
    inline function set_caretIndex(val:Int):Int return cState.caretIndex = val;

    static function makeStyleNamesByType():Map<ConsoleTokenType, String> {
        var styleNamesByType:Map<ConsoleTokenType, String> = new Map();
        styleNamesByType[Key] = ConsoleStrings.KEY_STYLENAME;
        styleNamesByType[Value] = ConsoleStrings.VALUE_STYLENAME;
        styleNamesByType[Flag] = ConsoleStrings.FLAG_STYLENAME;
        styleNamesByType[ActionName] = ConsoleStrings.ACTION_NAME_STYLENAME;
        styleNamesByType[Tail] = ConsoleStrings.TAIL_STYLENAME;
        styleNamesByType[TailMarker] = ConsoleStrings.TAIL_MARKER_STYLENAME;
        return styleNamesByType;
    }
}
