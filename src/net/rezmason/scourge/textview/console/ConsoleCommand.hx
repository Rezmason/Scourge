package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Zig;

class ConsoleCommand {

    static var ids:Int = 0;

    public var inputGeneratedSignal(default, null):Zig<Array<TextToken>->Int->Int->Void>;
    public var hintsGeneratedSignal(default, null):Zig<Array<TextToken>->Void>;
    public var outputGeneratedSignal(default, null):Zig<Array<TextToken>->Bool->Void>;


    public var tokenStyles(default, null):String;
    public var id(default, null):Int;
    public var nameStyle(default, null):String;
    public var hidden(default, null):Bool;

    public function new(hidden:Bool = false):Void {
        id = ids++;
        tokenStyles = '';
        nameStyle = '__input';
        this.hidden = hidden;
        inputGeneratedSignal = new Zig();
        hintsGeneratedSignal = new Zig();
        outputGeneratedSignal = new Zig();
    }

    public function requestHints(tokens:Array<TextToken>, info:InputInfo):Void {}
    public function execute(tokens:Array<TextToken>):Void {}
    public function handleHintHover(token:TextToken, isHovering:Bool):Void {}

    inline function makeToken(text:String = null, styleName:String = null, restriction:String = null):TextToken {
        return {text:text, authorID:null, spanID:null, data:null, styleName:styleName, restriction:restriction};
    }
}
