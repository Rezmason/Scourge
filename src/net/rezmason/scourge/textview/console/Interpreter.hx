package net.rezmason.scourge.textview.console;

import haxe.Utf8;

import net.rezmason.scourge.textview.console.Types;
import net.rezmason.utils.Utf8Utils.*;

class Interpreter {

    inline static var UNRECOGNIZED_COMMAND:String = 'Unrecognized command.';

    var console:ConsoleText;
    var commandsByName:Map<String, ConsoleCommand>;

    public function new():Void {
        commandsByName = new Map();
    }

    public function connectToConsole(console:ConsoleText):Void {
        if (this.console == console) return;
        disconnectFromConsole();
        this.console = console;
        console.hintSignal.add(onHintSignal);
        console.execSignal.add(onExecSignal);
        console.clickSignal.add(onClickSignal);
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
        if (!commandsByName.exists(name)) commandsByName[name] = command;
    }

    public function removeCommand(name:String):Void {
        commandsByName.remove(name);
    }

    function onHintSignal(tokens:Array<TextToken>, info:InputInfo):Void {
        var commandName:String = tokens[0].text;
        if (tokens.length == 1) {

            while (charAt(commandName, 0) == ' ') commandName = sub(commandName, 1);

            tokens[0].text = commandName;

            if (charAt(commandName, length(commandName) - 1) == ' ') {
                commandName = sub(commandName, 0, length(commandName) - 1);
                tokens[0].text = commandName;
                tokens.push({text:'', type:PLAIN_TEXT});
                info.tokenIndex = 1;
                info.caretIndex = 0;
                var command:ConsoleCommand = commandsByName[commandName];
                if (command == null) errorHint(tokens, info, UNRECOGNIZED_COMMAND);
                else command.getHint(tokens, info, console.receiveHint);
            } else {
                var potentialNames:Array<String> = [];
                for (name in commandsByName.keys()) {
                    if (name.indexOf(commandName) == 0) potentialNames.push(name);
                }

                if (potentialNames.length > 0) {
                    var hintTokens:Array<TextToken> = [];
                    for (name in potentialNames) {
                        hintTokens.push({
                            text:name,
                            type:SHORTCUT([
                                {text:'$name ', type:PLAIN_TEXT}
                            ]),
                            color:Colors.blue()
                        });
                    }
                    console.receiveHint(tokens, info.tokenIndex, info.caretIndex, hintTokens);
                } else {
                    errorHint(tokens, info, UNRECOGNIZED_COMMAND);
                }
            }
        } else {
            if (commandsByName.exists(commandName)) {
                commandsByName[commandName].getHint(tokens, info, console.receiveHint);
            } else {
                // Default behavior: tokens get cleaned up in response to changes
                if (info.char != '' && info.tokenIndex < tokens.length - 1) {
                    tokens = tokens.slice(0, info.tokenIndex + 1);
                }

                errorHint(tokens, info, UNRECOGNIZED_COMMAND);
            }
        }
    }

    function onExecSignal(tokens:Array<TextToken>):Void {
        var commandName:String = tokens[0].text;

        // console.receiveExec([{text:"Done.", type:PLAIN_TEXT}], true);
        if (commandsByName.exists(commandName)) {
            commandsByName[commandName].getExec(tokens, console.receiveExec);
        } else {
            errorExec(UNRECOGNIZED_COMMAND);
        }
    }

    function errorHint(tokens:Array<TextToken>, info:InputInfo, message:String):Void {
        for (token in tokens) token.color = Colors.red();
        console.receiveHint(tokens, info.tokenIndex, info.caretIndex, [{text:message, type:PLAIN_TEXT, color:Colors.red()}]);
    }

    function errorExec(message:String):Void {
        console.receiveExec([{text:message, type:PLAIN_TEXT, color:Colors.red()}], true);
    }

    function onClickSignal(name:String):Void {

    }
}
