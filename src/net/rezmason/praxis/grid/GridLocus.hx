package net.rezmason.praxis.grid;

@:allow(net.rezmason.praxis.grid.GridUtils)
class GridLocus<T> {
    public var value(default, null):T;
    public var neighbors(default, null):Array<GridLocus<T>>;
    public var id(default, null):Int;

    var _orthoNeighbors:Array<GridLocus<T>>;
    var _diagNeighbors:Array<GridLocus<T>>;

    public function new(id:Int, value:T):Void {
        this.value = value;
        this.id = id;
        neighbors = [];
        _orthoNeighbors = null;
        _diagNeighbors = null;
    }
}
