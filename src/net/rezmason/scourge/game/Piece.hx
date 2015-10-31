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
        } else {
            rotation = 0;
            reflection = 0;
            variations = [[new Piece(data, this)]];
        }
    }

    public inline function getVariant(reflection:Int = 0, rotation:Int = 0):Piece {
        if (variations == null) throw 'Cannot get variant of non-free piece';
        reflection = reflection % numReflections;
        rotation = rotation % numRotations;
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
        var oldX:Float = reflection == 1 ? -coord.x : coord.x;
        var oldY:Float = coord.y;

        oldX -= center.x;
        oldY -= center.y;

        var newX:Float = 0;
        var newY:Float = 0;

        switch (rotation) {
            case 0: 
                newX =  oldX;
                newY =  oldY;
            case 1:
                newX =  oldY;
                newY = -oldX;
            case 2:
                newX = -oldX;
                newY = -oldY;
            case 3:
                newX = -oldY;
                newY =  oldX;
        }

        newX += center.x;
        newY += center.y;

        return {x:Std.int(newX), y:Std.int(newY)};
    }

    public inline function footprint(includeCells, includeEdges, includeCorners) {
        var footprint = [];
        if (includeCells) footprint = footprint.concat(cells);
        if (includeEdges) footprint = footprint.concat(edges);
        if (includeCorners) footprint = footprint.concat(corners);
        return footprint;
    }
}
