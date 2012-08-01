package net.rezmason.scourge.model;

import haxe.FastList;

class GridNode<T> extends FastList<T> {
    public var value(getValue, null):T;
    public var neighbors(default, null):Array<GridNode<T>>;
    public function new():Void { super(); neighbors = []; }
    public function cut():Void { head.next = null; }
    inline function getValue():T { return first(); }
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
