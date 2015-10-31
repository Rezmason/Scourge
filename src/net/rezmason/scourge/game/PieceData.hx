package net.rezmason.scourge.game;

typedef PieceData = {
    var id:String;
    var cells:Array<Coord<Int>>;
    var corners:Array<Coord<Int>>;
    var edges:Array<Coord<Int>>;
    var center:Coord<Float>;
    var numReflections:Int;
    var numRotations:Int;

    @:optional var rotation:Int;
    @:optional var reflection:Int;
}
