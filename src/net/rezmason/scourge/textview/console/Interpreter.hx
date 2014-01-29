package net.rezmason.scourge.textview.console;

import haxe.Utf8;
import haxe.ds.ArraySort;
import net.rezmason.utils.StringSort;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Utf8Utils.*;


class Interpreter {

    inline static var UNRECOGNIZED_COMMAND:String = 'Unrecognized command.';
    inline static var HINT_BUTTON_STYLE_ELEMENTS:String =
        '§{name:hintUp  , p: 0.00, f:0.5}' +
        '§{name:hintOver, p:-0.01, f:0.6}' +
        '§{name:hintDown, p: 0.01, f:0.4}';

    var console:ConsoleUIMediator;
    var commandsByName:Map<String, ConsoleCommand>;
    var commandsByID:Map<Int, ConsoleCommand>;

    public function new():Void {
        commandsByName = new Map();
        commandsByID = new Map();
    }

    public function connectToConsole(console:ConsoleUIMediator):Void {
        if (this.console == console) return;
        disconnectFromConsole();
        this.console = console;
        console.hintSignal.add(onHintSignal);
        console.runSignal.add(onRunSignal);
        console.buttonSignal.add(onButtonSignal);

        console.loadStyles(HINT_BUTTON_STYLE_ELEMENTS);
        for (command in commandsByName) connectCommandToConsole(command);
    }

    public function disconnectFromConsole():Void {
        if (this.console != null) {
            console.hintSignal.remove(onHintSignal);
            console.runSignal.remove(onRunSignal);
            console.buttonSignal.remove(onButtonSignal);
            for (command in commandsByName) disconnectCommandFromConsole(command);
            this.console = null;
        }
    }

    public function addCommand(name:String, command:ConsoleCommand):Void {
        commandsByName[name] = command;
        commandsByID[command.id] = command;
        if (console != null) connectCommandToConsole(command);
    }

    public function removeCommand(name:String):Void {
        var command:ConsoleCommand = commandsByName[name];
        if (command != null) {
            commandsByName.remove(name);
            commandsByID.remove(command.id);
            if (console != null) disconnectCommandFromConsole(command);
        }
    }

    inline function connectCommandToConsole(command:ConsoleCommand):Void {
        console.loadStyles(command.tokenStyles);
        command.inputGeneratedSignal.add(console.receiveInput);
        command.hintsGeneratedSignal.add(console.receiveHints);
        command.outputGeneratedSignal.add(console.receiveOutput);
    }

    inline function disconnectCommandFromConsole(command:ConsoleCommand):Void {
        command.inputGeneratedSignal.remove(console.receiveInput);
        command.hintsGeneratedSignal.remove(console.receiveHints);
        command.outputGeneratedSignal.remove(console.receiveOutput);
    }

    function onHintSignal(tokens:Array<TextToken>, info:InputInfo):Void {

        if (info.char != '' && tokens.length > info.tokenIndex + 1) {
            tokens.splice(info.tokenIndex + 1, tokens.length);
        }

        var commandName:String = tokens[0].text;
        if (tokens.length == 1) {

            // Initial command; try to recognize it

            // (First, get rid of any extra spaces at the beginning)
            commandName = ltrim(commandName);
            tokens[0].text = commandName;

            if (info.char == ' ') {
                // Looks like the first token is 'complete'.
                // We trim that space on the end.
                commandName = rtrim(commandName);
                tokens[0].text = commandName;
                info.caretIndex = length(commandName);

                // Does the command name match any registered command?
                var command:ConsoleCommand = commandsByName[commandName];
                if (command != null) {
                    command.requestHints(tokens, info);
                    return;
                }

                // Otherwise, the first token wasn't *really* complete.
            }

            // The user is still entering the command name.
            // Let's provide a list of possible matches to what they've typed so far.

            var potentialNames:Array<String> = [];
            for (name in commandsByName.keys()) {
                if (name.indexOf(commandName) == 0) potentialNames.push(name);
            }

            if (potentialNames.length > 0) {
                ArraySort.sort(potentialNames, StringSort.sort);
                // We make a shortcut for each match.
                var hintTokens:Array<TextToken> = [];
                for (name in potentialNames) {
                    if (commandsByName[name].hidden) continue;
                    var token:TextToken = makeToken(name, commandsByName[name].nameStyle);
                    token.authorID = -1;
                    token.data = {tokens:[token, {text:''}]};
                    hintTokens.push(token);
                }
                tokens[0].styleName = null;
                console.receiveHints(hintTokens);
                console.receiveInput(tokens, info.tokenIndex, info.caretIndex);
            } else {
                // No matches; we tell the user.
                sendErrorHint(tokens, info, UNRECOGNIZED_COMMAND);
            }
        } else {
            if (commandsByName.exists(commandName)) {
                // Valid command names mean there's a command to handle this.
                tokens[0].styleName = null;
                commandsByName[commandName].requestHints(tokens, info);
            } else {
                // Weird state that could only occur if a command or comm bungled the input.

                // Trim subsequent tokens. Go home, input. You're drunk.
                tokens = tokens.slice(0, info.tokenIndex + 1);
                info.tokenIndex = 0;
                info.caretIndex = length(tokens[0].text);

                sendErrorHint(tokens, info, UNRECOGNIZED_COMMAND);
            }
        }
    }

    function onRunSignal(tokens:Array<TextToken>):Void {
        var commandName:String = tokens[0].text;
        var command:ConsoleCommand = commandsByName[commandName];
        if (command != null) command.execute(tokens);
        else sendErrorExec(UNRECOGNIZED_COMMAND);
    }

    function onButtonSignal(token:TextToken, type:MouseInteractionType):Void {
        var authorID:Null<Int> = token.authorID;
        if (authorID == -1) {
            switch (type) {
                case CLICK: handleClickedShortcut(token, commandsByName[token.text]);
                case _:
            }
        } else if (authorID != null && authorID >= 0) {
            var command:ConsoleCommand = commandsByID[token.authorID];
            if (command != null) {
                switch (type) {
                    case CLICK: handleClickedShortcut(token, command);
                    case ENTER: command.handleHintHover(token, true);
                    case EXIT: command.handleHintHover(token, false);
                    case _:
                }
            }
        }

    }

    function handleClickedShortcut(token:TextToken, command:ConsoleCommand):Void {
        if (token.data != null) {
            var tokens:Array<TextToken> = token.data.tokens;
            var info:InputInfo = {tokenIndex:tokens.length - 1, caretIndex: length(tokens[tokens.length - 1].text), char:''};
            command.requestHints(tokens, info);
        }
    }

    function sendErrorHint(tokens:Array<TextToken>, info:InputInfo, message:String):Void {
        var errorToken:TextToken = makeToken(message, Strings.ERROR_HINT_STYLENAME);
        errorToken.authorID = -1;
        console.receiveHints([errorToken]);

        for (token in tokens) token.styleName = Strings.ERROR_INPUT_STYLENAME;
        console.receiveInput(tokens, info.tokenIndex, info.caretIndex);
    }

    function sendErrorExec(message:String):Void {
        var errorToken:TextToken = makeToken(message, Strings.ERROR_EXEC_STYLENAME);
        errorToken.authorID = -1;
        console.receiveOutput([errorToken], true);
    }

    inline function makeButtonStyle(name:String):String return 'µ{name:interpreter_$name, up:hintUp, over:hintOver, down:hintDown, period:0.2, i:1}';

    inline function makeToken(text:String = null, styleName:String = null, restriction:String = null):TextToken {
        return {text:text, authorID:null, spanID:null, data:null, styleName:styleName, restriction:null};
    }
}
