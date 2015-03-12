package net.rezmason.scourge.game.build;

import net.rezmason.praxis.grid.GridDirection.*;
import net.rezmason.scourge.XYZ;
import net.rezmason.scourge.game.build.PetriTypes;

using net.rezmason.praxis.grid.GridUtils;

class PetriBoardFactory {

    // Creates boards for "skirmish games"

    private  static var PLAYER_DIST:Int = 9;
    private inline static var RIM:Int = 1;
    private inline static var PADDING:Int = 5 + RIM;
    private inline static var START_ANGLE:Float = 0.75;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    public static function create(numPlayers:Int = 2, circular:Bool = false, initGrid:String = null):Array<PetriLocus> {

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var headAngle:Float = 2 / numPlayers;
        var boardRadius:Float = (numPlayers == 1) ? 0 : PLAYER_DIST / (2 * Math.sin(Math.PI * headAngle * 0.5));

        // First, find the bounds of the rectangle containing all heads as if they were arranged on a circle

        var headCoords:Array<XYZ> = [];
        for (ike in 0...numPlayers) {
            var angle:Float = Math.PI * (ike * headAngle + START_ANGLE);
            var coord:XYZ = {x:0, y:0, z:0};
            headCoords.push(coord);
            coord.x = Math.cos(angle) * boardRadius;
            coord.y = Math.sin(angle) * boardRadius;
        }

        var minHeadX:Float = Math.POSITIVE_INFINITY;
        var minHeadY:Float = Math.POSITIVE_INFINITY;
        var maxHeadX:Float = Math.NEGATIVE_INFINITY;
        var maxHeadY:Float = Math.NEGATIVE_INFINITY;
        
        for (coord in headCoords) {
            if (minHeadX > coord.x) minHeadX = coord.x;
            if (minHeadY > coord.y) minHeadY = coord.y;
            if (maxHeadX < coord.x) maxHeadX = coord.x;
            if (maxHeadY < coord.y) maxHeadY = coord.y;
        }

        // For some values of numPlayers, the heads will be relatively evenly spaced
        // but relatively unevenly positioned away from the edges of the board.
        // So we scale their positions to fit within a square.

        var headScaleX:Float = (maxHeadX - minHeadX + 1) / (2 * boardRadius);
        var headScaleY:Float = (maxHeadY - minHeadY + 1) / (2 * boardRadius);

        minHeadX = Math.floor(minHeadX / headScaleX);
        minHeadY = Math.floor(minHeadY / headScaleY);
        maxHeadX = Math.floor(maxHeadX / headScaleX);
        maxHeadY = Math.floor(maxHeadY / headScaleY);

        for (coord in headCoords) {
            coord.x = Std.int(Math.floor(coord.x / headScaleX) + PADDING - minHeadX);
            coord.y = Std.int(Math.floor(coord.y / headScaleY) + PADDING - minHeadY);
        }

        var boardWidth:Int = Std.int(maxHeadX - minHeadX + 1 + 2 * PADDING);
        var loci:Array<PetriLocus> = makeSquareGraph(boardWidth);
        var topLeft = loci[0];
        var hasInitGrid:Bool = initGrid != null && initGrid.length > 0;
        obstructGraphRim(topLeft);
        if (circular) encircleGraph(topLeft, boardWidth * 0.5 - RIM);
        populateGraphHeads(topLeft, headCoords);
        if (hasInitGrid) initGraph(topLeft, initGrid, boardWidth);

        for (locus in loci) {
            var pos = locus.value.pos;
            pos.x = (pos.x - (boardWidth - 1) / 2);
            pos.y = (pos.y - (boardWidth - 1) / 2);
            pos.z = (pos.x * pos.x + pos.y * pos.y) * -0.02;
        }

        return loci;
    }

    inline static function makeSquareGraph(width:Int):Array<PetriLocus> {

        var loci = [];

        // Make a connected grid of nodes with default values
        var locus:PetriLocus = addLocus(loci, 0, 0);
        var row:PetriLocus = locus;
        for (ike in 1...width) locus = locus.attach(addLocus(loci, ike, 0), E);

        for (ike in 1...width) {
            for (column in row.walk(E)) {
                var next:PetriLocus = addLocus(loci, column.value.pos.x, ike);
                column.attach(next, S);
                next.attach(column.w(), NW);
                next.attach(column.e(), NE);
                next.attach(column.sw(), W);
            }
            row = row.s();
        }

        // run to the northwest
        return loci;
    }

    inline static function addLocus(loci:Array<PetriLocus>, x:Float, y:Float):PetriLocus {
        var locus = new PetriLocus(loci.length, {pos:{x:x, y:y, z:0}, isWall:false, isHead:false, owner:-1});
        loci.push(locus);
        return locus;
    }

    inline static function obstructGraphRim(grid:PetriLocus):Void {
        for (locus in grid.walk(E)) locus.value.isWall = true;
        for (locus in grid.walk(S)) locus.value.isWall = true;
        for (locus in grid.run(S).walk(E)) locus.value.isWall = true;
        for (locus in grid.run(E).walk(S)) locus.value.isWall = true;
    }

    inline static function populateGraphHeads(grid:PetriLocus, headCoords:Array<XYZ>):Void {
        for (ike in 0...headCoords.length) {
            var coord:XYZ = headCoords[ike];
            var head = grid.run(E, Std.int(coord.x)).run(S, Std.int(coord.y)).value;
            head.isHead = true;
            head.owner = ike;
        }
    }

    inline static function encircleGraph(grid:PetriLocus, radius:Float):Void {
        // Circular levels' cells are obstructed if they're too far from the board's center

        var y:Int = 0;
        for (row in grid.walk(S)) {
            var x:Int = 0;
            for (column in row.walk(E)) {
                if (!column.value.isWall) {
                    var fx:Float = x - radius + 0.5 - RIM;
                    var fy:Float = y - radius + 0.5 - RIM;
                    var insideCircle:Bool = Math.sqrt(fx * fx + fy * fy) < radius;
                    if (!insideCircle) column.value.isWall = true;
                }
                x++;
            }
            y++;
        }
    }

    inline static function initGraph(grid:PetriLocus, initGrid:String, boardWidth:Int):Void {

        // Refer to the initGrid to assign initial values to nodes

        var initGridWidth:Int = boardWidth + 1;

        initGrid = INIT_GRID_CLEANER.replace(initGrid, '');

        var y:Int = 0;
        for (row in grid.walk(S)) {
            var x:Int = 0;
            for (column in row.walk(E)) {
                var datum = column.value;
                if (!datum.isWall) {
                    var char:String = initGrid.charAt(y * initGridWidth + x + 1);
                    if (char == ' ') {
                        datum.owner = -1;
                        datum.isHead = false;
                    } else {
                        if (!NUMERIC_CHAR.match(char)) datum.isWall = true;
                        else datum.owner = Std.parseInt(char);
                    }
                }
                x++;
            }
            y++;
        }
    }
}
