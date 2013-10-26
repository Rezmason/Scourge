package net.rezmason.ropes;

class GridLocus<T> {
    public var value(default, null):T;
    public var neighbors(default, null):Array<GridLocus<T>>;
    public var headingOffsets(default, null):Array<Int>;

    @:allow(net.rezmason.ropes.GridUtils) var id:Int;

    public function new(id:Int, value:T):Void {
        this.value = value;
        this.id = id;
        neighbors = [];
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
