package net.rezmason.scourge.game.build;

import net.rezmason.grid.GridDirection.*;
import net.rezmason.scourge.Vec3;
import net.rezmason.scourge.game.build.PetriTypes;

using net.rezmason.grid.GridUtils;

class PetriBoardFactory {

    // Creates boards for "skirmish games"

    private  static var PLAYER_DIST:Int = 9;
    private inline static var RIM:Int = 1;
    private inline static var PADDING:Int = 5 + RIM;
    private inline static var START_ANGLE:Float = 0.75;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    public static function create(numPlayers:Int = 2, circular:Bool = false, initGrid:String = null):Array<PetriCell> {

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var headAngle:Float = 2 / numPlayers;
        var innerRadius:Float = (numPlayers == 1) ? 0 : PLAYER_DIST / (2 * Math.sin(Math.PI * headAngle * 0.5));

        // First, find the bounds of the rectangle containing all heads as if they were arranged on a circle

        var headCoords:Array<Vec3> = [];
        for (ike in 0...numPlayers) {
            var angle:Float = Math.PI * (ike * headAngle + START_ANGLE);
            var coord:Vec3 = new Vec3(0, 0, 0);
            headCoords.push(coord);
            coord.x = Math.cos(angle) * innerRadius;
            coord.y = Math.sin(angle) * innerRadius;
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

        var headScaleX:Float = (maxHeadX - minHeadX + 1) / (2 * innerRadius);
        var headScaleY:Float = (maxHeadY - minHeadY + 1) / (2 * innerRadius);

        minHeadX = Math.floor(minHeadX / headScaleX);
        minHeadY = Math.floor(minHeadY / headScaleY);
        maxHeadX = Math.floor(maxHeadX / headScaleX);
        maxHeadY = Math.floor(maxHeadY / headScaleY);

        for (coord in headCoords) {
            coord.x = Std.int(Math.floor(coord.x / headScaleX) + PADDING - minHeadX);
            coord.y = Std.int(Math.floor(coord.y / headScaleY) + PADDING - minHeadY);
        }

        var boardWidth:Int = Std.int(maxHeadX - minHeadX + 1 + 2 * PADDING);
        var cells:Array<PetriCell> = makeSquareGraph(boardWidth);
        var topLeft = cells[0];
        var hasInitGrid:Bool = initGrid != null && initGrid.length > 0;
        obstructGraphRim(topLeft);
        if (circular) encircleGraph(topLeft, boardWidth * 0.5 - RIM);
        populateGraphHeads(topLeft, headCoords);
        if (hasInitGrid) initGraph(topLeft, initGrid, boardWidth);

        var outerRadius:Float = (boardWidth - 1) / 2;
        for (cell in cells) {
            var pos = cell.value.pos;
            pos.x = pos.x - outerRadius;
            pos.y = outerRadius - pos.y;
            pos.z = (pos.x * pos.x + pos.y * pos.y) * -0.02;
        }

        return cells;
    }

    inline static function makeSquareGraph(width:Int):Array<PetriCell> {

        var cells = [];

        // Make a connected grid of spaces with default values
        var cell:PetriCell = addCell(cells, 0, 0);
        var row:PetriCell = cell;
        for (ike in 1...width) cell = cell.attach(addCell(cells, ike, 0), E);

        for (ike in 1...width) {
            for (column in row.walk(E)) {
                var next:PetriCell = addCell(cells, column.value.pos.x, ike);
                column.attach(next, S);
                next.attach(column.w(), NW);
                next.attach(column.e(), NE);
                next.attach(column.sw(), W);
            }
            row = row.s();
        }

        // run to the northwest
        return cells;
    }

    inline static function addCell(cells:Array<PetriCell>, x:Float, y:Float):PetriCell {
        var cell = new PetriCell(cells.length, {pos:new Vec3(x, y, 0), isWall:false, isHead:false, owner:-1});
        cells.push(cell);
        return cell;
    }

    inline static function obstructGraphRim(grid:PetriCell):Void {
        for (cell in grid.walk(E)) cell.value.isWall = true;
        for (cell in grid.walk(S)) cell.value.isWall = true;
        for (cell in grid.run(S).walk(E)) cell.value.isWall = true;
        for (cell in grid.run(E).walk(S)) cell.value.isWall = true;
    }

    inline static function populateGraphHeads(grid:PetriCell, headCoords:Array<Vec3>):Void {
        for (ike in 0...headCoords.length) {
            var coord:Vec3 = headCoords[ike];
            var head = grid.run(E, Std.int(coord.x)).run(S, Std.int(coord.y)).value;
            head.isHead = true;
            head.owner = ike;
        }
    }

    inline static function encircleGraph(grid:PetriCell, radius:Float):Void {
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

    inline static function initGraph(grid:PetriCell, initGrid:String, boardWidth:Int):Void {

        // Refer to the initGrid to assign initial values to spaces

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
