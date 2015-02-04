package net.rezmason.scourge.model.meta;

import net.rezmason.ropes.RopesTypes;

typedef ReplenishableProperty = {
    var prop:AspectProperty;
    var amount:Int;
    var period:Int;
    var maxAmount:Int;
    @:optional var replenishableID:Int;
}
