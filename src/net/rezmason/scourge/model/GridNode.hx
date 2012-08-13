package net.rezmason.scourge.model;

class GridNode<T> {
    public var value:T;
    public var neighbors(default, null):Array<GridNode<T>>;
    public function new():Void { neighbors = []; }
}

typedef Gr = GridDirection;

class GridDirection {
    public inline static var nw:Int = 0;
    public inline static var  n:Int = 1;
    public inline static var ne:Int = 2;
    public inline static var  e:Int = 3;
    public inline static var se:Int = 4;
    public inline static var  s:Int = 5;
    public inline static var sw:Int = 6;
    public inline static var  w:Int = 7;
}
