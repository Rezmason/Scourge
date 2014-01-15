package net.rezmason.scourge.textview.text;

class AnimatedSpanState extends SpanState {

    public var time:Float;
    public var playing:Bool;

    public function new():Void {
        super();
        time = 0;
        playing = true;
    }
}
