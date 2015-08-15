package net.rezmason.grid;

@:allow(net.rezmason.grid.GridUtils)
class Cell<T> {
    public var value(default, null):T;
    public var neighbors(default, null):Array<Cell<T>>;
    public var id(default, null):UInt;

    var _orthoNeighbors:Array<Cell<T>>;
    var _diagNeighbors:Array<Cell<T>>;

    public function new(id:UInt, value:T):Void {
        this.value = value;
        this.id = id;
        neighbors = [];
        _orthoNeighbors = null;
        _diagNeighbors = null;
    }
}
