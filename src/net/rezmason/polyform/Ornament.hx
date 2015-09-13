package net.rezmason.polyform;

@:enum abstract Ornament(String) to String {
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
