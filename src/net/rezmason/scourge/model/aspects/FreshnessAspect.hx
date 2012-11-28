package net.rezmason.scourge.model.aspects;

import net.rezmason.ropes.Aspect;

class FreshnessAspect extends Aspect {
    @aspect(0) var FRESHNESS;
    @aspect(0) var MAX_FRESHNESS;

    @aspect(null) var FRESH_FIRST;
    @aspect(null) var FRESH_NEXT;
    @aspect(null) var FRESH_PREV;
}
