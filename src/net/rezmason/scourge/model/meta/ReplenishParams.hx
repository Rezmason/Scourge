package net.rezmason.scourge.model.meta;

typedef ReplenishParams = {
    var globalProperties:Map<String, ReplenishableProperty>;
    var playerProperties:Map<String, ReplenishableProperty>;
    var nodeProperties:Map<String, ReplenishableProperty>;
}
