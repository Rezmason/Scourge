package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.PraxisTypes;

typedef PickPieceMove = {>Move,
    var hatIndex:Int;
    var pieceTableID:Int;
    var rotation:Int;
    var reflection:Int;
}
