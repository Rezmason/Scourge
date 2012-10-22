package net.rezmason.scourge.model.aspects;

class ReplenishableAspect extends Aspect {
    @aspect(Aspect.NULL) var STATE_REP_FIRST;
    @aspect(Aspect.NULL) var PLAYER_REP_FIRST;
    @aspect(Aspect.NULL) var NODE_REP_FIRST;

    @aspect(Aspect.NULL) var REP_NEXT;
    @aspect(Aspect.NULL) var REP_PREV;
    @aspect(Aspect.NULL) var REP_ID;

    @aspect(Aspect.NULL) var REP_PROP_LOOKUP;
    @aspect(0) var REP_STEP;
}
