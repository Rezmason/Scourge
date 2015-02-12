package net.rezmason.praxis.grid;

@:enum abstract GridDirection(Int) {
    @:to public inline function toInt():Int return cast this;
    var  N = 0;
    var NE = 1;
    var  E = 2;
    var SE = 3;
    var  S = 4;
    var SW = 5;
    var  W = 6;
    var NW = 7;
}
