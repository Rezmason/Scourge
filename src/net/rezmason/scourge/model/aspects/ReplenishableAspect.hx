package net.rezmason.scourge.model.aspects;

class ReplenishableAspect extends Aspect {
    @aspect(NULL) var STATE_REP_FIRST;
    @aspect(NULL) var PLAYER_REP_FIRST;
    @aspect(NULL) var NODE_REP_FIRST;

    @aspect(NULL) var REP_NEXT;
    @aspect(NULL) var REP_PREV;
    @aspect(NULL) var REP_ID;

    @aspect(NULL) var REP_PROP_LOOKUP;
    @aspect(0) var REP_STEP;
}
