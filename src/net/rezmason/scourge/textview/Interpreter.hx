package net.rezmason.scourge.textview;

import haxe.Utf8;

import net.rezmason.utils.Utf8Utils.*;

private typedef Indices = {
    var t:Int;
    var c:Int;
}

class Interpreter {

    inline static var NO_MATCHING_COMMAND:String = 'No command matches that name.';
    inline static var COMMAND_NOT_FOUND:String = 'No command has that name.';

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

    function onHintSignal(tokens:Array<TextToken>, indices:Indices):Void {
        var commandName:String = tokens[0].text;
        if (tokens.length == 1) {
            while (charAt(commandName, 0) == ' ') commandName = sub(commandName, 1);
            if (commandName == '') return;

            tokens[0].text = commandName;

            if (charAt(commandName, length(commandName) - 1) == ' ') {
                commandName = sub(commandName, 0, length(commandName) - 1);
                tokens[0].text = commandName;
                tokens.push({text:'', type:PLAIN_TEXT, color:Colors.white()});
                indices.t = 1;
                indices.c = 0;
                commandsByName[commandName].getHint(tokens, indices, console.receiveHint);
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
                                {text:'$name ', type:PLAIN_TEXT, color:Colors.white()}
                            ]),
                            color:Colors.blue()
                        });
                    }
                    console.receiveHint(tokens, indices.t, indices.c, hintTokens);
                } else {
                    errorHint(tokens, indices, NO_MATCHING_COMMAND);
                }
            }
        } else if (commandsByName.exists(commandName)) {
            commandsByName[commandName].getHint(tokens, indices, console.receiveHint);
        } else {
            errorHint(tokens, indices, COMMAND_NOT_FOUND);
        }
    }

    function onExecSignal(tokens:Array<TextToken>):Void {
        var commandName:String = tokens[0].text;

        // console.receiveExec([{text:"Done.", type:PLAIN_TEXT, color:Colors.white()}], true);
        if (commandsByName.exists(commandName)) {
            commandsByName[commandName].getExec(tokens, console.receiveExec);
        } else {
            errorExec(COMMAND_NOT_FOUND);
        }
    }

    function errorHint(tokens:Array<TextToken>, indices:Indices, message:String):Void {
        for (token in tokens) token.color = Colors.red();
        console.receiveHint(tokens, indices.t, indices.c, [{text:message, type:PLAIN_TEXT, color:Colors.red()}]);
    }

    function errorExec(message:String):Void {
        console.receiveExec([{text:message, type:PLAIN_TEXT, color:Colors.red()}], true);
    }

    function onClickSignal(name:String):Void {

    }
}
