package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect;

class PieceAspect extends Aspect {
    @aspect(0) var PIECES_PICKED;
    @aspect(null) var PIECE_FIRST;
    @aspect(null) var PIECE_NEXT;
    @aspect(null) var PIECE_PREV;
    @aspect(null) var PIECE_HAT_FIRST;
    @aspect(null) var PIECE_HAT_PLAYER;
    @aspect(null) var PIECE_HAT_NEXT;
    @aspect(null) var PIECE_HAT_PREV;

    @aspect(null) var PIECE_TABLE_INDEX;
    @aspect(0) var PIECE_REFLECTION;
    @aspect(0) var PIECE_ROTATION;
    @aspect(null) var PIECE_MOVE_ID;
}
