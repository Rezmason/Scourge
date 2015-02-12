package net.rezmason.scourge.model.body;

import net.rezmason.ropes.aspect.Aspect;

class OwnershipAspect extends Aspect {
    @aspect(false) var IS_FILLED;
    @aspect(null) var OCCUPIER;
}
