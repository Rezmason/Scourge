package net.rezmason.polyform;

@:enum abstract Ornament(String) to String {
    var EMPTY = ' ';

    var CELL = '•';
    var CORNER = '+';
    var EDGE = 'o';

    var NORTH = '^';
    var EAST = '>';
    var SOUTH = 'v';
    var WEST = '<';
    
    var STEP_LEFT = 'L';
    var STEP_RIGHT = 'R';
    var STEP_STRAIGHT = 'S';
}
