package net.rezmason.scourge.game;

typedef Coord<T:(Float)> = {
    var x(default, null):T;
    var y(default, null):T;
}

private typedef _Piece = {
    public var cells(default, null):Array<Coord<Int>>;
    public var corners(default, null):Array<Coord<Int>>;
    public var edges(default, null):Array<Coord<Int>>;
    public var center(default, null):Coord<Float>;
}

@:forward abstract Piece(_Piece) {
    public inline function new(data:_Piece) this = data;
    public inline function footprint(includeCells, includeEdges, includeCorners) {
        var footprint = [];
        if (includeCells) footprint = footprint.concat(this.cells);
        if (includeEdges) footprint = footprint.concat(this.edges);
        if (includeCorners) footprint = footprint.concat(this.corners);
        return footprint;
    }
}

abstract FreePiece(Array<Array<Piece>>) {
    public inline function new(data:Array<Array<_Piece>>) {
        this = [for (reflection in data) [for (datum in reflection) new Piece(datum)]];
    }
    public inline function getPiece(reflection, rotation):Piece return this[reflection][rotation];
    public var numReflections(get, never):Int; inline function get_numReflections() return this.length;
    public var numRotations(get, never):Int; inline function get_numRotations() return this[0].length;
}
