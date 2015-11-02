package net.rezmason.scourge.game;

class Piece {

    public var id(default, null):String;
    public var cells(default, null):Array<Coord<Int>>;
    public var corners(default, null):Array<Coord<Int>>;
    public var edges(default, null):Array<Coord<Int>>;
    public var center(default, null):Coord<Float>;
    public var numReflections(default, null):Int;
    public var numRotations(default, null):Int;
    public var rotation(default, null):Int;
    public var reflection(default, null):Int;
    public var closestCellToCenter(default, null):Coord<Int>;

    public var origin(default, null):Piece;
    var variations:Array<Array<Piece>>;

    public function new(data:PieceData, origin:Piece = null) {
        id = data.id;
        cells = data.cells;
        corners = data.corners;
        edges = data.edges;
        center = data.center;
        numReflections = data.numReflections;
        numRotations = data.numRotations;

        if (origin != null) {
            rotation = data.rotation;
            reflection = data.reflection;
            this.origin = origin;
            
            closestCellToCenter = cells[origin.cells.indexOf(origin.closestCellToCenter)];
        } else {
            rotation = 0;
            reflection = 0;

            var minDistSquared = Math.POSITIVE_INFINITY;
            for (cell in cells) {
                var cx = cell.x - center.x;
                var cy = cell.y - center.y;
                var distSquared = cx * cx + cy * cy;
                if (closestCellToCenter == null || minDistSquared > distSquared) {
                    minDistSquared = distSquared;
                    closestCellToCenter = cell;
                }
            }
            
            variations = [[new Piece(data, this)]];
        }

    }

    public inline function getVariant(reflection:Int = 0, rotation:Int = 0):Piece {
        if (variations == null) throw 'Cannot get variant of non-free piece';
        if (variations[reflection] == null) variations[reflection] = [];
        if (variations[reflection][rotation] == null) {
            var variationData:PieceData = {
                id:id,
                cells:[for (cell in cells) transformCoord(cell, reflection, rotation)],
                corners:[for (corner in corners) transformCoord(corner, reflection, rotation)],
                edges:[for (edge in edges) transformCoord(edge, reflection, rotation)],
                center:center,
                numReflections:numReflections,
                numRotations:numRotations,
                rotation:rotation,
                reflection:reflection,
            };
            variations[reflection][rotation] = new Piece(variationData, this);
        }
        return variations[reflection][rotation];
    }

    inline function transformCoord(coord, reflection, rotation):Coord<Int> {
        var oldX = reflection == 1 ? -coord.x : coord.x;
        var oldY = coord.y;

        return switch (rotation) {
            case 0: {x:  oldX, y:  oldY};
            case 1: {x:  oldY, y: -oldX};
            case 2: {x: -oldX, y: -oldY};
            case 3: {x: -oldY, y:  oldX};
            case _: null;
        }
    }

    public inline function footprint(includeCells, includeEdges, includeCorners) {
        var footprint = [];
        if (includeCells) footprint = footprint.concat(cells);
        if (includeEdges) footprint = footprint.concat(edges);
        if (includeCorners) footprint = footprint.concat(corners);
        return footprint;
    }
}
