package net.rezmason.scourge.components;

import net.rezmason.ecce.Entity;
import net.rezmason.praxis.PraxisTypes.AspectSet;
import net.rezmason.praxis.grid.GridLocus;
import net.rezmason.scourge.game.build.PetriTypes;

class BoardNodeState {
    public var values:AspectSet;
    public var lastValues:AspectSet;
    public var petriData:PetriData;
    public var locus:GridLocus<Entity>;
}
