package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.Types;

class ConsoleCommand {

    static var ids:Int = 0;

    public var tokenStyles(default, null):String;
    public var id(default, null):Int;
    public var nameStyle(default, null):String;

    public function new():Void {
        id = ids++;
        tokenStyles = '';
        nameStyle = '__input';
    }

    public function getHint(tokens:Array<TextToken>, info:InputInfo, callback:HintCallback):Void {

    }

    public function getExec(tokens:Array<TextToken>, callback:ExecCallback):Void {

    }

    public function resolveTokenShortcut(token:TextToken):Array<TextToken> {
        return token.payload;
    }

    public function handleHintHover(token:TextToken, isHovering:Bool):Void {

    }
}
