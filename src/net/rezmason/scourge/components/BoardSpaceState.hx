package net.rezmason.scourge.components;

import net.rezmason.ecce.Entity;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.Cell;
import net.rezmason.scourge.game.build.PetriTypes;

class BoardSpaceState {
    public var values:Space;
    public var lastValues:Space;
    public var petriData:PetriData;
    public var cell:Cell<Entity>;
}
