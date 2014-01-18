package net.rezmason.scourge.textview.console;

import haxe.Utf8;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.console.Types;
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
        console.execSignal.add(onExecSignal);
        console.buttonSignal.add(onButtonSignal);

        console.loadStyles(HINT_BUTTON_STYLE_ELEMENTS);
        for (command in commandsByName) console.loadStyles(command.tokenStyles);
    }

    public function disconnectFromConsole():Void {
        if (this.console != null) {
            console.hintSignal.remove(onHintSignal);
            console.execSignal.remove(onExecSignal);
            console.buttonSignal.remove(onButtonSignal);
            this.console = null;
        }
    }

    public function addCommand(name:String, command:ConsoleCommand):Void {
        commandsByName[name] = command;
        commandsByID[command.id] = command;
        if (console != null) console.loadStyles(command.tokenStyles);
    }

    public function removeCommand(name:String):Void {
        var command:ConsoleCommand = commandsByName[name];
        if (command != null) {
            commandsByName.remove(name);
            commandsByID.remove(command.id);
        }
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
                    command.getHint(tokens, info, console.receiveHint);
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
                // We make a shortcut for each match.
                var hintTokens:Array<TextToken> = [];
                for (name in potentialNames) {
                    var token:TextToken = {
                        text:name,
                        styleName:commandsByName[name].nameStyle,
                        authorID:-1
                    };
                    token.payload = [token, {text:''}];
                    hintTokens.push(token);
                }
                tokens[0].styleName = null;
                console.receiveHint(tokens, info.tokenIndex, info.caretIndex, hintTokens);
            } else {
                // No matches; we tell the user.
                sendErrorHint(tokens, info, UNRECOGNIZED_COMMAND);
            }
        } else {
            if (commandsByName.exists(commandName)) {
                // Valid command names mean there's a command to handle this.
                tokens[0].styleName = null;
                commandsByName[commandName].getHint(tokens, info, console.receiveHint);
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

    function onExecSignal(tokens:Array<TextToken>):Void {
        var commandName:String = tokens[0].text;
        var command:ConsoleCommand = commandsByName[commandName];
        if (command != null) command.getExec(tokens, console.receiveExec);
        else sendErrorExec(UNRECOGNIZED_COMMAND);
    }

    function onButtonSignal(token:TextToken, type:MouseInteractionType):Void {

        var command:ConsoleCommand = null;
        var authorID:Null<Int> = token.authorID;
        if (authorID == -1) {
            switch (type) {
                case CLICK: sendShortcutInput(resolveTokenShortcut(token));
                case _:
            }
        } else if (authorID != null && authorID >= 0) {
            command = commandsByID[token.authorID];
        }

        if (command != null) {
            switch (type) {
                case CLICK: sendShortcutInput(command.resolveTokenShortcut(token));
                case ENTER: command.handleHintHover(token, true);
                case EXIT: command.handleHintHover(token, false);
                case _:
            }
        }
    }

    function resolveTokenShortcut(token:TextToken):Array<TextToken> {
        return token.payload;
    }

    function sendShortcutInput(tokens:Array<TextToken>):Void {
        var info:InputInfo = {tokenIndex:tokens.length - 1, caretIndex: length(tokens[tokens.length - 1].text), char:''};
        commandsByName[tokens[0].text].getHint(tokens, info, console.receiveHint);
    }

    function sendErrorHint(tokens:Array<TextToken>, info:InputInfo, message:String):Void {
        for (token in tokens) token.styleName = Strings.ERROR_INPUT_STYLENAME;
        console.receiveHint(tokens, info.tokenIndex, info.caretIndex, [{text:message, styleName:Strings.ERROR_HINT_STYLENAME}]);
    }

    function sendErrorExec(message:String):Void {
        console.receiveExec([{text:message, styleName:Strings.ERROR_EXEC_STYLENAME}], true);
    }

    function onClickSignal(name:String):Void {

    }

    inline function makeButtonStyle(name:String):String return 'µ{name:interpreter_$name, up:hintUp, over:hintOver, down:hintDown, period:0.2, i:1}';
}
