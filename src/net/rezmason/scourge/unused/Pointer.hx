package net.rezmason.scourge.unused;

class Pointer<T> {

    private static var ids:Int = 0;

    public var value:T;
    public var id(default, null):Int;

    public function new():Void {
        id = ids++;
    }

    public function toString():String { return "*" + Std.string(value); }
}
