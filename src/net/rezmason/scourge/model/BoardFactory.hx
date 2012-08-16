package net.rezmason.scourge.model;

import haxe.FastList;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.Aspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.IntHashUtils;

typedef XY = {x:Float, y:Float};
typedef BoardData = {boardWidth:Int, headCoords:Array<XY>};

class BoardFactory {

    // Creates boards for "skirmish games"
    // I suspect that this is actually a rule. Might refactor in the future

    private inline static var PLAYER_DIST:Int = 9;
    private inline static var RIM:Int = 1;
    private inline static var PADDING:Int = 5 + RIM;
    private inline static var START_ANGLE:Float = 0.75;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    public function new():Void {

    }

    public function makeBoard(cfg:BoardConfig, history:History<Int>):Array<BoardNode> {
        if (cfg == null) return null;

        var historyArray:Array<Int> = history.array;

        var heads:Array<BoardNode> = [];

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var numPlayers:Int = cfg.numPlayers;
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



        var grid:BoardNode = makeSquareGraph(boardWidth, history);
        obstructGraphRim(grid, historyArray);
        populateGraphHeads(grid, headCoords, heads, historyArray);
        if (cfg.circular) encircleGraph(grid, boardWidth * 0.5 - RIM, historyArray);
        if (cfg.initGrid != null && cfg.initGrid.length > 0) initGraph(grid, cfg.initGrid, boardWidth, historyArray);

        return heads;
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

    inline function makeNode(history:History<Int>):BoardNode {
        var aspects:Aspects = new Aspects();
        aspects.set(OwnershipAspect.id, new OwnershipAspect(history));
        return new BoardNode(aspects);
    }

    inline function nodeOwner(node:BoardNode):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }

    inline function makeSquareGraph(width:Int, history:History<Int>):BoardNode {

        // Make a connected grid of nodes with default values
        var node:BoardNode = makeNode(history);
        for (ike in 1...width) node = node.attach(makeNode(history), Gr.e);

        var row:BoardNode = node.run(Gr.w);
        for (ike in 1...width) {
            for (column in row.walk(Gr.e)) {
                var next:BoardNode = makeNode(history);
                column.attach(next, Gr.s);
                next.attach(column.w(), Gr.nw);
                next.attach(column.e(), Gr.ne);
                next.attach(column.sw(), Gr.w);
            }
            row = row.s();
        }

        // run to the northwest
        return node.run(Gr.nw).run(Gr.n).run(Gr.w);
    }

    inline function obstructGraphRim(grid:BoardNode, historyArray:Array<Int>):Void {
        for (node in grid.walk(Gr.e)) historyArray[nodeOwner(node).isFilled] = 1;
        for (node in grid.walk(Gr.s)) historyArray[nodeOwner(node).isFilled] = 1;
        for (node in grid.run(Gr.s).walk(Gr.e)) historyArray[nodeOwner(node).isFilled] = 1;
        for (node in grid.run(Gr.e).walk(Gr.s)) historyArray[nodeOwner(node).isFilled] = 1;
    }

    inline function populateGraphHeads(grid:BoardNode, headCoords:Array<XY>, heads:Array<BoardNode>, historyArray:Array<Int>):Void {
        // Identify and change the occupier of each head node

        for (ike in 0...headCoords.length) {
            var coord:XY = headCoords[ike];
            heads[ike] = grid.run(Gr.e, coord.x.int()).run(Gr.s, coord.y.int());
            var ownerAspect:OwnershipAspect = nodeOwner(heads[ike]);
            historyArray[ownerAspect.isFilled] = 1;
            historyArray[ownerAspect.occupier] = ike;
        }
    }

    inline function encircleGraph(grid:BoardNode, radius:Float, historyArray:Array<Int>):Void {
        // Circular levels' cells are obstructed if they're too far from the board's center

        var y:Int = 0;
        for (row in grid.walk(Gr.s)) {
            var x:Int = 0;
            for (column in row.walk(Gr.e)) {
                var ownerAspect:OwnershipAspect = nodeOwner(column);
                if (historyArray[ownerAspect.isFilled] == 0) {
                    var fx:Float = x - radius + 0.5 - RIM;
                    var fy:Float = y - radius + 0.5 - RIM;
                    var insideCircle:Bool = Math.sqrt(fx * fx + fy * fy) < radius;
                    if (!insideCircle) historyArray[ownerAspect.isFilled] = 1;
                }
                x++;
            }
            y++;
        }
    }

    inline function initGraph(grid:BoardNode, initGrid:String, boardWidth:Int, historyArray:Array<Int>):Void {

        // Refer to the initGrid to assign initial values to nodes

        var initGridWidth:Int = boardWidth + 1;

        initGrid = INIT_GRID_CLEANER.replace(initGrid, "");

        var y:Int = 0;
        for (row in grid.walk(Gr.s)) {
            var x:Int = 0;
            for (column in row.walk(Gr.e)) {
                var ownerAspect:OwnershipAspect = nodeOwner(column);
                if (historyArray[ownerAspect.isFilled] == 0) {
                    var char:String = initGrid.charAt(y * initGridWidth + x + 1);
                    if (char != " ") {
                        historyArray[ownerAspect.isFilled] = 1;
                        if (!NUMERIC_CHAR.match(char)) historyArray[ownerAspect.occupier] = -1;
                        else historyArray[ownerAspect.occupier] = Std.parseInt(char);
                    }
                }
                x++;
            }
            y++;
        }
    }
}
