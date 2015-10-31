package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.PieceTypes;

typedef DropPieceMove = {>Move,
    var targetSpace:Int;
    var numAddedSpaces:Int;
    var addedSpaces:Array<Int>;
    var rotation:Int;
    var reflection:Int;
    var coord:Coord<Int>;
    var duplicate:Bool;
}
