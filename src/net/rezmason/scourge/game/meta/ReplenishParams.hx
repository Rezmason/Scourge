package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.PraxisTypes;

typedef ReplenishParams = {
    var globalProperties:Map<String, ReplenishableProperty<PGlobal>>;
    var playerProperties:Map<String, ReplenishableProperty<PPlayer>>;
    var cardProperties:Map<String, ReplenishableProperty<PCard>>;
    var spaceProperties:Map<String, ReplenishableProperty<PSpace>>;
}
