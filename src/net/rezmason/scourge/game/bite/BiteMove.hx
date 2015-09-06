package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.PraxisTypes;

typedef BiteMove = {>Move,
    var targetSpace:Int;
    var bitSpaces:Array<Int>;
    var thickness:Int;
    var duplicate:Bool;
}
