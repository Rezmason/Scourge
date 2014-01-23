package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;

class TextCommand extends ConsoleCommand {

    var func:String->String;

    public function new(func:String->String, hidden:Bool = false):Void {
        super(hidden);
        // tokenStyles = '';
        this.func = func;
    }

    override public function getHint(tokens:Array<TextToken>, info:InputInfo, callback:HintCallback):Void {
        if (tokens.length == 1) {
            // Let's move the caret to a new token.
            tokens.push({text:''});
            info.tokenIndex = 1;
            info.caretIndex = 0;
        }

        callback(tokens, info.tokenIndex, info.caretIndex, []);
    }

    override public function getExec(tokens:Array<TextToken>, callback:ExecCallback):Void {
        callback([{text:func(tokens.map(function(tok):String return tok.text).join(' '))}], true);
    }
}
