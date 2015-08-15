package net.rezmason.scourge.game.build;

import net.rezmason.grid.Cell;
import net.rezmason.grid.Grid;

typedef PetriData = {
    var pos:Vec3;
    var isWall:Bool;
    var isHead:Bool;
    var owner:Int;
}

typedef PetriCell = Cell<PetriData>;
typedef PetriGrid = Grid<PetriData>;
