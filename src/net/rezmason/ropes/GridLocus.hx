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

typedef Gr = GridDirection;

class GridDirection {
    public inline static var  n:Int = 0;
    public inline static var ne:Int = 1;
    public inline static var  e:Int = 2;
    public inline static var se:Int = 3;
    public inline static var  s:Int = 4;
    public inline static var sw:Int = 5;
    public inline static var  w:Int = 6;
    public inline static var nw:Int = 7;
}
