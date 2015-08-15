package net.rezmason.scourge.game.build;

import net.rezmason.grid.Cell;

typedef PetriData = {
    var pos:Vec3;
    var isWall:Bool;
    var isHead:Bool;
    var owner:Int;
}

typedef PetriCell = Cell<PetriData>;
