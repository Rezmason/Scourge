package net.rezmason.scourge.model;

abstract IntCoord(Array<Int>) {
    public inline function new(data) this = data;
    public inline function x() return this[0];
    public inline function y() return this[1];
}

abstract Piece(Array<Array<IntCoord>>) {
    public inline function new(data:Array<Array<Dynamic>>) {
        this = [for (series in data) [for (datum in series) new IntCoord(datum)]];
    }
    public inline function cells() return this[0];
    public inline function edges() return this[1];
    public inline function corners() return this[2];
    public inline function footprint(includeCells, includeEdges, includeCorners) {
        var footprint = [];
        if (includeCells) footprint = footprint.concat(cells());
        if (includeEdges) footprint = footprint.concat(edges());
        if (includeCorners) footprint = footprint.concat(corners());
        return footprint;
    }
}

abstract FreePiece(Array<Array<Piece>>) {
    public inline function new(data:Array<Array<Dynamic>>) {
        this = [for (reflection in data) [for (datum in reflection) new Piece(datum)]];
    }
    public inline function getPiece(reflection, rotation):Piece return this[reflection][rotation];
    public inline function numReflections() return this.length;
    public inline function numRotations() return this[0].length;
}
