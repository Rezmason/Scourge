package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.PraxisTypes;

typedef PickPieceMove = {>Move,
    var hatIndex:Int;
    var pieceTableIndex:Int;
    var rotation:Int;
    var reflection:Int;
}
