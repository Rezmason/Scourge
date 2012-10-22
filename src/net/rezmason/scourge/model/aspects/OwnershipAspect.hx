package net.rezmason.scourge.model.aspects;

class OwnershipAspect extends Aspect {
    @aspect(Aspect.FALSE) var IS_FILLED;
    @aspect(Aspect.NULL) var OCCUPIER;
}
