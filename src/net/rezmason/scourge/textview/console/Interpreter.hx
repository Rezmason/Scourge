package net.rezmason.scourge.textview.console;

import haxe.Utf8;

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

    public function new():Void {
        commandsByName = new Map();
    }

    public function connectToConsole(console:ConsoleUIMediator):Void {
        if (this.console == console) return;
        disconnectFromConsole();
        this.console = console;
        console.hintSignal.add(onHintSignal);
        console.execSignal.add(onExecSignal);
        console.clickSignal.add(onClickSignal);

        console.loadStyles(Strings.ERROR_STYLES + HINT_BUTTON_STYLE_ELEMENTS);
        for (command in commandsByName) console.loadStyles(command.tokenStyles);
    }

    public function disconnectFromConsole():Void {
        if (this.console != null) {
            console.hintSignal.remove(onHintSignal);
            console.execSignal.remove(onExecSignal);
            console.clickSignal.remove(onClickSignal);
            this.console = null;
        }
    }

    public function addCommand(name:String, command:ConsoleCommand):Void {
        commandsByName[name] = command;
        if (console != null) console.loadStyles(command.tokenStyles);
    }

    public function removeCommand(name:String):Void commandsByName.remove(name);

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
                    hintTokens.push({
                        text:name,
                        type:SHORTCUT([
                            {text:'$name ', type:PLAIN_TEXT}
                        ]),
                        styleName:'potentialNameHint'
                    });
                }
                tokens[0].styleName = null;
                console.receiveHint(tokens, info.tokenIndex, info.caretIndex, hintTokens);
            } else {
                // No matches; we tell the user.
                errorHint(tokens, info, UNRECOGNIZED_COMMAND);
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

                errorHint(tokens, info, UNRECOGNIZED_COMMAND);
            }
        }
    }

    function onExecSignal(tokens:Array<TextToken>):Void {
        var commandName:String = tokens[0].text;
        var command:ConsoleCommand = commandsByName[commandName];
        if (command != null) command.getExec(tokens, console.receiveExec);
        else errorExec(UNRECOGNIZED_COMMAND);
    }

    function errorHint(tokens:Array<TextToken>, info:InputInfo, message:String):Void {
        for (token in tokens) token.styleName = Strings.ERROR_HINT_STYLENAME;
        console.receiveHint(tokens, info.tokenIndex, info.caretIndex, [{text:message, type:PLAIN_TEXT}]);
    }

    function errorExec(message:String):Void {
        console.receiveExec([{text:message, type:PLAIN_TEXT, styleName:Strings.ERROR_EXEC_STYLENAME}], true);
    }

    function onClickSignal(name:String):Void {

    }

    inline function makeButtonStyle(name:String):String return 'µ{name:interpreter_$name, up:hintUp, over:hintOver, down:hintDown, period:0.2, i:1}';
}
