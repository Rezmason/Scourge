package net.rezmason.ropes;

@:allow(net.rezmason.ropes.GridUtils)
class GridLocus<T> {
    public var value(default, null):T;
    public var neighbors(default, null):Array<GridLocus<T>>;
    public var headingOffsets(default, null):Array<Int>;

    var _orthoNeighbors:Array<GridLocus<T>>;
    var _diagNeighbors:Array<GridLocus<T>>;

    var id:Int;

    public function new(id:Int, value:T):Void {
        this.value = value;
        this.id = id;
        neighbors = [];
        _orthoNeighbors = null;
        _diagNeighbors = null;
        headingOffsets = [0, 0, 0, 0, 0, 0, 0, 0];
    }
}
