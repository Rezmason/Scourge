package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.Types;

class ConsoleCommand {

    static var ids:Int = 0;

    public var tokenStyles(default, null):String;
    public var id(default, null):Int;
    public var nameStyle(default, null):String;
    public var hidden(default, null):Bool;

    public function new(hidden:Bool = false):Void {
        id = ids++;
        tokenStyles = '';
        nameStyle = '__input';
        this.hidden = hidden;
    }

    public function getHint(tokens:Array<TextToken>, info:InputInfo, callback:HintCallback):Void {

    }

    public function getExec(tokens:Array<TextToken>, callback:ExecCallback):Void {

    }

    public function handleHintHover(token:TextToken, isHovering:Bool):Void {

    }
}
