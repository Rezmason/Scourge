package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;

class TextCommand extends ConsoleCommand {

    var func:Array<String>->String;

    public function new(func:Array<String>->String, hidden:Bool = false):Void {
        super(hidden);
        // tokenStyles = '';
        this.func = func;
    }

    override public function requestHints(tokens:Array<TextToken>, info:InputInfo):Void {
        if (tokens.length == 1) {
            // Let's move the caret to a new token.
            tokens.push(makeToken(''));
            info.tokenIndex = 1;
            info.caretIndex = 0;
        }

        inputGeneratedSignal.dispatch(tokens, info.tokenIndex, info.caretIndex);
    }

    override public function execute(tokens:Array<TextToken>):Void {
        outputGeneratedSignal.dispatch([makeToken(func(tokens.map(function(tok):String return tok.text)))], true);
    }
}
