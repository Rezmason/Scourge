package net.rezmason.scourge.components;

import net.rezmason.ecce.Entity;
import net.rezmason.praxis.PraxisTypes.AspectSet;
import net.rezmason.grid.Cell;
import net.rezmason.scourge.game.build.PetriTypes;

class BoardSpaceState {
    public var values:AspectSet;
    public var lastValues:AspectSet;
    public var petriData:PetriData;
    public var cell:Cell<Entity>;
}
