package net.rezmason.scourge.game.build;

import net.rezmason.praxis.grid.GridLocus;

typedef PetriData = {
    var pos:Vec3;
    var isWall:Bool;
    var isHead:Bool;
    var owner:Int;
}

typedef PetriLocus = GridLocus<PetriData>;
