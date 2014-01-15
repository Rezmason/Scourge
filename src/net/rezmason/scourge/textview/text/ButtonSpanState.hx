package net.rezmason.scourge.textview.text;

class ButtonSpanState extends SpanState {

    public var time:Float;
    public var fromIndex:Int;
    public var toIndex:Int;
    public var ratio:Float;
    public var mouseIsOver:Bool;
    public var mouseIsDown:Bool;

    public function new():Void {
        super();
        time = 0;
        fromIndex = 0;
        toIndex = 0;
        mouseIsOver = false;
        mouseIsDown = false;
        ratio = 1;
    }
}
