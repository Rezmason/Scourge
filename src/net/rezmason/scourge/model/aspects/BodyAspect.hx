package net.rezmason.scourge.model.aspects;

class BodyAspect extends Aspect {
    @aspect(Aspect.NULL) var NODE_ID;
    @aspect(Aspect.NULL) var HEAD;
    @aspect(Aspect.NULL) var BODY_FIRST;
    @aspect(Aspect.NULL) var BODY_NEXT;
    @aspect(Aspect.NULL) var BODY_PREV;

    @aspect(0) var TOTAL_AREA;

    @aspect(Aspect.NULL) var CAVITY_FIRST;
    @aspect(Aspect.NULL) var CAVITY_NEXT;
    @aspect(Aspect.NULL) var CAVITY_PREV;
}
