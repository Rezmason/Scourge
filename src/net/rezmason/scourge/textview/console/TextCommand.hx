package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.Types;

class TextCommand extends ConsoleCommand {

    var func:String->String;

    public function new(func:String->String):Void {
        super();
        this.func = func;
    }

    override public function getHint(tokens:Array<TextToken>, info:InputInfo, callback:HintCallback):Void {
        callback(tokens, info.tokenIndex, info.caretIndex, []);
    }

    override public function getExec(tokens:Array<TextToken>, callback):Void {
        callback([{text:func(tokens.map(function(tok):String return tok.text).join(' ')), type:PLAIN_TEXT, color:Colors.blue()}], true);
    }
}
