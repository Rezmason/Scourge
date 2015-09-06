package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.PraxisTypes;

typedef ReplenishableProperty<T> = {
    var prop:AspectProperty<T>;
    var amount:Int;
    var period:Int;
    var maxAmount:Int;
    @:optional var replenishableID:Int;
    @:optional var replenishablePtr:AspectWritePointer<T>;
}
