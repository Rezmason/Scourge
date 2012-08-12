package net.rezmason.scourge.model;

class Record<T> {

    private static var ids:Int = 0;

    public var value:T;
    public var id(default, null):Int;

    public function new():Void {
        id = ids++;
    }
}
