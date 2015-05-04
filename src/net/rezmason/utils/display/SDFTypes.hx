package net.rezmason.utils.display;

import haxe.io.Bytes;

class Datum {
    public var dx:Float;
    public var dy:Float;
    public var rad2:Float;
    public var row:Int;
    public var col:Int;
    public var pending:Bool;
    public var side:Int;

    public function new():Void {}

    public function pop(row, col, dx, dy, rad2, pending, side):Void {
        this.dx = dx;
        this.dy = dy;
        this.rad2 = rad2;
        this.row = row;
        this.col = col;
        this.pending = pending;
        this.side = side;
    }
}

typedef SerializedBitmap = {
    var width:Int;
    var height:Int;
    var bytes:Bytes;
}

typedef Work = {source:SerializedBitmap, cutoff:Int};
