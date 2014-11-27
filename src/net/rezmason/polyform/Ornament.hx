package net.rezmason.polyform;

@:enum abstract Ornament(String) {
    @:to public inline function toString():String return cast this;
    var EMPTY = ' ';

    var CELL = '•';
    var CORNER = '+';
    var EDGE = 'o';

    var NORTH = '“';
    var EAST = '»';
    var SOUTH = '„';
    var WEST = '«';
    
    var STEP_LEFT = '+';
    var STEP_RIGHT = '◊';
    var STEP_STRAIGHT = '#';
}
