package net.rezmason.scourge.model;

abstract IntCoord(Array<Int>) {
    public inline function new(data) this = data;
    public var x(get, never):Int; inline function get_x() return this[0];
    public var y(get, never):Int; inline function get_y() return this[1];
}

abstract Piece(Array<Array<IntCoord>>) {
    public inline function new(data:Array<Array<Dynamic>>) {
        this = [for (series in data) [for (datum in series) new IntCoord(datum)]];
    }
    public var cells(get, never):Array<IntCoord>; inline function get_cells() return this[0];
    public var edges(get, never):Array<IntCoord>; inline function get_edges() return this[1];
    public var corners(get, never):Array<IntCoord>; inline function get_corners() return this[2];
    public inline function footprint(includeCells, includeEdges, includeCorners) {
        var footprint = [];
        if (includeCells) footprint = footprint.concat(cells);
        if (includeEdges) footprint = footprint.concat(edges);
        if (includeCorners) footprint = footprint.concat(corners);
        return footprint;
    }
}

abstract FreePiece(Array<Array<Piece>>) {
    public inline function new(data:Array<Array<Dynamic>>) {
        this = [for (reflection in data) [for (datum in reflection) new Piece(datum)]];
    }
    public inline function getPiece(reflection, rotation):Piece return this[reflection][rotation];
    public var numReflections(get, never):Int; inline function get_numReflections() return this.length;
    public var numRotations(get, never):Int; inline function get_numRotations() return this[0].length;
}
