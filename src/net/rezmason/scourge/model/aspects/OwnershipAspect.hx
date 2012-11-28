package net.rezmason.scourge.model.aspects;

import net.rezmason.ropes.Aspect;

class OwnershipAspect extends Aspect {
    @aspect(false) var IS_FILLED;
    @aspect(null) var OCCUPIER;
}
