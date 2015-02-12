package net.rezmason.scourge.model.build;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.grid.GridDirection.*;
import net.rezmason.ropes.grid.GridLocus;
import net.rezmason.ropes.rule.BaseRule;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.TempParams;

using Lambda;
using net.rezmason.ropes.aspect.AspectUtils;
using net.rezmason.ropes.grid.GridUtils;
using net.rezmason.utils.Pointers;

typedef XY = {x:Float, y:Float};

class BuildBoardRule extends BaseRule<FullBuildBoardParams> {

    // Creates boards for "skirmish games"

    private  static var PLAYER_DIST:Int = 9;
    private inline static var RIM:Int = 1;
    private inline static var PADDING:Int = 5 + RIM;
    private inline static var START_ANGLE:Float = 0.75;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;

    override private function _prime():Void {

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var numPlayers:Int = params.numPlayers;
        var headAngle:Float = 2 / numPlayers;
        var boardRadius:Float = (numPlayers == 1) ? 0 : PLAYER_DIST / (2 * Math.sin(Math.PI * headAngle * 0.5));

        // First, find the bounds of the rectangle containing all heads as if they were arranged on a circle

        var headCoords:Array<XY> = [];
        for (ike in 0...numPlayers) {
            var angle:Float = Math.PI * (ike * headAngle + START_ANGLE);
            var coord:XY = {x:0., y:0.};
            headCoords.push(coord);
            coord.x = Math.cos(angle) * boardRadius;
            coord.y = Math.sin(angle) * boardRadius;
        }

        var minCoord:XY = findMinCoord(headCoords);
        var maxCoord:XY = findMaxCoord(headCoords);
        var scaleX:Float = (maxCoord.x - minCoord.x + 1) / (2 * boardRadius);
        var scaleY:Float = (maxCoord.y - minCoord.y + 1) / (2 * boardRadius);

        // For some values of numPlayers, the heads will be relatively evenly spaced
        // but relatively unevenly positioned away from the edges of the board.
        // So we scale their positions to fit within a square.

        for (coord in headCoords) {
            coord.x = Math.floor(coord.x / scaleX);
            coord.y = Math.floor(coord.y / scaleY);
        }

        minCoord = findMinCoord(headCoords);
        maxCoord = findMaxCoord(headCoords);

        // The square's width and the positions of each head are returned.

        var boardWidth:Int = Std.int(maxCoord.x - minCoord.x + 1 + 2 * PADDING);

        for (coord in headCoords) {
            coord.x = Std.int(coord.x + PADDING - minCoord.x);
            coord.y = Std.int(coord.y + PADDING - minCoord.y);
        }

        var grid:BoardLocus = makeSquareGraph(boardWidth);
        var hasInitGrid:Bool = params.initGrid != null && params.initGrid.length > 0;
        obstructGraphRim(grid);
        if (params.circular) encircleGraph(grid, boardWidth * 0.5 - RIM);
        if (hasInitGrid) initGraph(grid, params.initGrid, boardWidth);
        populateGraphHeads(grid, headCoords, !hasInitGrid);
        populateGraphBodies();
    }

    inline function findMinCoord(coords:Array<XY>):XY {
        var minX:Float = Math.POSITIVE_INFINITY;
        var minY:Float = Math.POSITIVE_INFINITY;
        for (coord in coords) {
            if (minX > coord.x) minX = coord.x;
            if (minY > coord.y) minY = coord.y;
        }
        return {x:minX, y:minY};
    }

    inline function findMaxCoord(coords:Array<XY>):XY {
        var maxX:Float = Math.NEGATIVE_INFINITY;
        var maxY:Float = Math.NEGATIVE_INFINITY;

        for (coord in coords) {
            if (maxX < coord.x) maxX = coord.x;
            if (maxY < coord.y) maxY = coord.y;
        }
        return {x:maxX, y:maxY};
    }

    inline function makeSquareGraph(width:Int):BoardLocus {

        // Make a connected grid of nodes with default values
        var locus:BoardLocus = getNodeLocus(addNode());
        for (ike in 1...width) locus = locus.attach(getNodeLocus(addNode()), E);

        var row:BoardLocus = locus.run(W);
        for (ike in 1...width) {
            for (column in row.walk(E)) {
                var next:BoardLocus = getNodeLocus(addNode());
                column.attach(next, S);
                next.attach(column.w(), NW);
                next.attach(column.e(), NE);
                next.attach(column.sw(), W);
            }
            row = row.s();
        }

        // run to the northwest
        return locus.run(NW).run(N).run(W);
    }

    inline function obstructGraphRim(grid:BoardLocus):Void {
        for (locus in grid.walk(E)) locus.value[isFilled_] = TRUE;
        for (locus in grid.walk(S)) locus.value[isFilled_] = TRUE;
        for (locus in grid.run(S).walk(E)) locus.value[isFilled_] = TRUE;
        for (locus in grid.run(E).walk(S)) locus.value[isFilled_] = TRUE;
    }

    inline function populateGraphHeads(grid:BoardLocus, headCoords:Array<XY>, plantHeads:Bool):Void {
        // Identify and change the occupier of each head node

        for (ike in 0...headCoords.length) {
            var coord:XY = headCoords[ike];
            var head:BoardLocus = grid.run(E, Std.int(coord.x)).run(S, Std.int(coord.y));
            if (plantHeads) {
                head.value[isFilled_] = TRUE;
                head.value[occupier_] = ike;
                getPlayer(ike)[head_] = getID(head.value);
            } else if (head.value[isFilled_] == TRUE && head.value[occupier_] == ike) {
                getPlayer(ike)[head_] = getID(head.value);
            }
        }
    }

    inline function encircleGraph(grid:BoardLocus, radius:Float):Void {
        // Circular levels' cells are obstructed if they're too far from the board's center

        var y:Int = 0;
        for (row in grid.walk(S)) {
            var x:Int = 0;
            for (column in row.walk(E)) {
                if (column.value[isFilled_] == 0) {
                    var fx:Float = x - radius + 0.5 - RIM;
                    var fy:Float = y - radius + 0.5 - RIM;
                    var insideCircle:Bool = Math.sqrt(fx * fx + fy * fy) < radius;
                    if (!insideCircle) column.value[isFilled_] = 1;
                }
                x++;
            }
            y++;
        }
    }

    inline function initGraph(grid:BoardLocus, initGrid:String, boardWidth:Int):Void {

        // Refer to the initGrid to assign initial values to nodes

        var initGridWidth:Int = boardWidth + 1;

        initGrid = INIT_GRID_CLEANER.replace(initGrid, '');

        var y:Int = 0;
        for (row in grid.walk(S)) {
            var x:Int = 0;
            for (column in row.walk(E)) {
                if (column.value[isFilled_] == FALSE) {
                    var char:String = initGrid.charAt(y * initGridWidth + x + 1);
                    if (char != ' ') {
                        column.value[isFilled_] = TRUE;
                        if (!NUMERIC_CHAR.match(char)) column.value[occupier_] = NULL;
                        else column.value[occupier_] = Std.parseInt(char);
                    }
                }
                x++;
            }
            y++;
        }
    }

    inline function populateGraphBodies():Void {

        var bodies:Array<Array<AspectSet>> = [];
        for (player in eachPlayer()) bodies.push([]);

        for (locus in eachLocus()) {
            if (locus.value[isFilled_] != FALSE) {
                var occupier:Int = locus.value[occupier_];
                if (occupier != NULL) {
                    if (bodies[occupier] == null) throw 'A node is owned by a player that doesn\'t exist: $occupier';
                    else bodies[occupier].push(locus.value);
                }
            }
        }

        for (player in eachPlayer()) {
            var body:Array<AspectSet> = bodies[getID(player)];
            if (body.length > 0) {
                var bodyFirstNode:AspectSet = body[0];
                player[bodyFirst_] = getID(bodyFirstNode);
                body.chainByAspect(ident_, bodyNext_, bodyPrev_);
            }
        }
    }
}
