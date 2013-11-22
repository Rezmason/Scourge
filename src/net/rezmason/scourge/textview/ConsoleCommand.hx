package net.rezmason.scourge.textview;

typedef HintCallback = Array<TextToken> -> Int -> Int -> Array<TextToken> -> Void;
typedef ExecCallback = Array<TextToken> -> Bool -> Void;

private typedef Indices = {
    var t:Int;
    var c:Int;
}

class ConsoleCommand {

    public function new():Void {

    }

    public function getHint(tokens:Array<TextToken>, indices:Indices, callback:HintCallback):Void {

    }

    public function getExec(tokens:Array<TextToken>, callback:ExecCallback):Void {

    }
}
