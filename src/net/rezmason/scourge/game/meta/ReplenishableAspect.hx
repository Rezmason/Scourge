package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect;

class ReplenishableAspect extends Aspect {
    @aspect(null) var GLOBAL_REP_FIRST;
    @aspect(null) var PLAYER_REP_FIRST;
    @aspect(null) var CARD_REP_FIRST;
    @aspect(null) var NODE_REP_FIRST;

    @aspect(null) var REP_NEXT;
    @aspect(null) var REP_PREV;

    @aspect(0) var REP_STEP;
}
