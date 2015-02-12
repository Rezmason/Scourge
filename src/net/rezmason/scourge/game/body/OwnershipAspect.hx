package net.rezmason.scourge.game.body;

import net.rezmason.praxis.aspect.Aspect;

class OwnershipAspect extends Aspect {
    @aspect(false) var IS_FILLED;
    @aspect(null) var OCCUPIER;
}
