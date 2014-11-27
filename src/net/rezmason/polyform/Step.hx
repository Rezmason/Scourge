package net.rezmason.polyform;

@:enum abstract Step(String) {
    @:to public inline function toString():String return cast this;
    var L = '0';
    var S = '1';
    var R = '2';
}
