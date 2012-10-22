package net.rezmason.scourge.model.aspects;

class BodyAspect extends Aspect {
    @aspect(NULL) var NODE_ID;
    @aspect(NULL) var HEAD;
    @aspect(NULL) var BODY_FIRST;
    @aspect(NULL) var BODY_NEXT;
    @aspect(NULL) var BODY_PREV;

    @aspect(0) var TOTAL_AREA;

    @aspect(NULL) var CAVITY_FIRST;
    @aspect(NULL) var CAVITY_NEXT;
    @aspect(NULL) var CAVITY_PREV;
}
