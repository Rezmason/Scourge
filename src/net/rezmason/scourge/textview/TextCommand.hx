package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.TokenType;

class TextCommand extends ConsoleCommand {

    var func:String->String;

    public function new(func:String->String):Void {
        super();
        this.func = func;
    }

    override public function getHint(tokens:Array<TextToken>, indices, callback):Void {
        callback(tokens, indices.t, indices.c, []);
    }

    override public function getExec(tokens:Array<TextToken>, callback):Void {
        callback([{text:func(tokens.map(function(tok):String return tok.text).join(' ')), type:PLAIN_TEXT, color:Colors.blue()}], true);
    }
}
