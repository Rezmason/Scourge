package net.rezmason.scourge.model.aspects;

import net.rezmason.ropes.Aspect;

class BodyAspect extends Aspect {
    @aspect(null) var NODE_ID;
    @aspect(null) var HEAD;
    @aspect(null) var BODY_FIRST;
    @aspect(null) var BODY_NEXT;
    @aspect(null) var BODY_PREV;

    @aspect(0) var TOTAL_AREA;

    @aspect(null) var CAVITY_FIRST;
    @aspect(null) var CAVITY_NEXT;
    @aspect(null) var CAVITY_PREV;
}
