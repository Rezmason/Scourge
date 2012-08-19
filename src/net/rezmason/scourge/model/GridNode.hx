package net.rezmason.scourge.model;

class GridNode<T> {
    public var value:T;
    public var neighbors(default, null):Array<GridNode<T>>;
    public function new(value:T):Void {
        this.value = value;
        neighbors = [];
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
