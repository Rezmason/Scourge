package net.rezmason.scourge.model.aspects;

class PieceAspect extends Aspect {
    @aspect(0) var PIECES_PICKED;
    @aspect(Aspect.NULL) var PIECE_FIRST;
    @aspect(Aspect.NULL) var PIECE_NEXT;
    @aspect(Aspect.NULL) var PIECE_PREV;
    @aspect(Aspect.NULL) var PIECE_HAT_FIRST;
    @aspect(Aspect.NULL) var PIECE_HAT_PLAYER;
    @aspect(Aspect.NULL) var PIECE_HAT_NEXT;
    @aspect(Aspect.NULL) var PIECE_HAT_PREV;

    @aspect(Aspect.NULL) var PIECE_ID;
    @aspect(Aspect.NULL) var PIECE_TABLE_ID;
    @aspect(0) var PIECE_REFLECTION;
    @aspect(0) var PIECE_ROTATION;
    @aspect(Aspect.NULL) var PIECE_OPTION_ID;
}
