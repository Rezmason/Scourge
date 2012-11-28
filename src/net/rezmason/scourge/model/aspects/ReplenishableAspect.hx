package net.rezmason.scourge.model.aspects;

import net.rezmason.ropes.Aspect;

class ReplenishableAspect extends Aspect {
    @aspect(null) var STATE_REP_FIRST;
    @aspect(null) var PLAYER_REP_FIRST;
    @aspect(null) var NODE_REP_FIRST;

    @aspect(null) var REP_NEXT;
    @aspect(null) var REP_PREV;
    @aspect(null) var REP_ID;

    @aspect(null) var REP_PROP_LOOKUP;
    @aspect(0) var REP_STEP;
}
