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
    private inline static var PADDING:Int = 5;
    private inline static var RIM:Int = 1;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    public function new():Void {

    }

    public function makeBoard(cfg:BoardConfig):Array<BoardNode> {
        if (cfg == null) return null;

        var heads:Array<BoardNode> = [];

        // Derive the size of the board and the positions of the players' heads
        var data:BoardData = designBoard(cfg.numPlayers, PLAYER_DIST, PADDING + RIM);
        // TODO: This is ugly. The whole class is ugly. Fix it.
        var boardWidth:Int = data.boardWidth;
        var headCoords:Array<XY> = data.headCoords;

        // Make a connected grid of nodes with default values
        var node:BoardNode = makeNode();
        for (ike in 1...boardWidth) node = node.attach(makeNode(), Gr.e);

        var row:BoardNode = node.run(Gr.w);
        for (ike in 1...boardWidth) {
            for (column in row.walk(Gr.e)) {
                var next:BoardNode = makeNode();
                column.attach(next, Gr.s);
                next.attach(column.w(), Gr.nw);
                next.attach(column.e(), Gr.ne);
                next.attach(column.sw(), Gr.w);
            }
            row = row.s();
        }

        // run to the northwest
        var grid:BoardNode = node.run(Gr.nw).run(Gr.n).run(Gr.w);

        // obstruct the rim
        for (node in grid.walk(Gr.e)) nodeOwner(node).isFilled = 1;
        for (node in grid.walk(Gr.s)) nodeOwner(node).isFilled = 1;
        for (node in grid.run(Gr.s).walk(Gr.e)) nodeOwner(node).isFilled = 1;
        for (node in grid.run(Gr.e).walk(Gr.s)) nodeOwner(node).isFilled = 1;

        // Identify and change the occupier of each head node
        for (ike in 0...cfg.numPlayers) {
            var coord:XY = headCoords[ike];
            heads[ike] = grid.run(Gr.e, coord.x.int()).run(Gr.s, coord.y.int());
            var ownerAspect:OwnershipAspect = nodeOwner(heads[ike]);
            ownerAspect.isFilled = 1;
            ownerAspect.occupier = ike;
        }

        // Circular levels' cells are obstructed if they're too far from the board's center
        // Note: This creates lots of nodes whose states never change...

        if (cfg.circular) {
            var radius:Float = (boardWidth - RIM * 2) * 0.5;
            var y:Int = 0;
            for (row in grid.walk(Gr.s)) {
                var x:Int = 0;
                for (column in row.walk(Gr.e)) {
                    var ownerAspect:OwnershipAspect = nodeOwner(column);
                    if (ownerAspect.isFilled == 0) {
                        var fx:Float = x - radius + 0.5 - RIM;
                        var fy:Float = y - radius + 0.5 - RIM;
                        var insideCircle:Bool = Math.sqrt(fx * fx + fy * fy) < radius;
                        if (!insideCircle) ownerAspect.isFilled = 1;
                    }
                    x++;
                }
                y++;
            }
        }

        // Refer to the initGrid to assign initial values to nodes

        if (cfg.initGrid != null && cfg.initGrid.length > 0) {

            var initGridWidth:Int = boardWidth + 1;

            var initGrid:String = INIT_GRID_CLEANER.replace(cfg.initGrid, "");

            var y:Int = 0;
            for (row in grid.walk(Gr.s)) {
                var x:Int = 0;
                for (column in row.walk(Gr.e)) {
                    var ownerAspect:OwnershipAspect = nodeOwner(column);
                    if (ownerAspect.isFilled == 0) {
                        var char:String = initGrid.charAt(y * initGridWidth + x + 1);
                        if (char != " ") {
                            ownerAspect.isFilled = 1;
                            if (!NUMERIC_CHAR.match(char)) ownerAspect.occupier = -1;
                            else ownerAspect.occupier = Std.int(Math.min(Std.parseInt(char), cfg.numPlayers));
                        }
                    }
                    x++;
                }
                y++;
            }
        }

        return heads;
    }

    inline function makeNode():BoardNode {
        var hash:IntHash<Aspect> = new IntHash<Aspect>();
        hash.set(OwnershipAspect.id, new OwnershipAspect());
        return new BoardNode(hash);
    }

    inline function nodeOwner(node:BoardNode):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }

    function designBoard(numPlayers:Int, playerDistance:Float, padding:Float):BoardData {

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var startAngle:Float = 0.75;
        var headAngle:Float = 2 / numPlayers;
        var boardRadius:Float = (numPlayers == 1) ? 0 : playerDistance / (2 * Math.sin(Math.PI * headAngle * 0.5));

        var minHeadX:Float = boardRadius * 2 + 1;
        var maxHeadX:Float = -1;
        var minHeadY:Float = boardRadius * 2 + 1;
        var maxHeadY:Float = -1;

        var coords:Array<XY> = [];

        // First, find the bounds of the rectangle containing all heads as if they were arranged on a circle

        for (ike in 0...numPlayers) {
            var angle:Float = Math.PI * (ike * headAngle + startAngle);
            var posX:Float = Math.cos(angle) * boardRadius;
            var posY:Float = Math.sin(angle) * boardRadius;

            minHeadX = Math.min(minHeadX, posX);
            minHeadY = Math.min(minHeadY, posY);
            maxHeadX = Math.max(maxHeadX, posX + 1);
            maxHeadY = Math.max(maxHeadY, posY + 1);
        }

        var scaleX:Float = (maxHeadX - minHeadX) / (2 * boardRadius);
        var scaleY:Float = (maxHeadY - minHeadY) / (2 * boardRadius);

        minHeadX = boardRadius * 2 + 1;
        maxHeadX = -1;
        minHeadY = boardRadius * 2 + 1;
        maxHeadY = -1;

        // For some values of numPlayers, the heads will be relatively evenly spaced
        // but relatively unevenly positioned away from the edges of the board.
        // So we scale their positions to fit within a square.

        for (ike in 0...numPlayers) {
            var coord:XY = {x:0., y:0.};
            coords.push(coord);

            var angle:Float = Math.PI * (ike * headAngle + startAngle);
            coord.x = Math.floor(Math.cos(angle) * boardRadius / scaleX);
            coord.y = Math.floor(Math.sin(angle) * boardRadius / scaleY);

            minHeadX = Math.min(minHeadX, coord.x);
            minHeadY = Math.min(minHeadY, coord.y);
            maxHeadX = Math.max(maxHeadX, coord.x + 1);
            maxHeadY = Math.max(maxHeadY, coord.y + 1);
        }

        // The square's width and the positions of each head are returned.

        var boardWidth:Int = Std.int(maxHeadX - minHeadX + 2 * padding);

        for (coord in coords) {
            coord.x = Std.int(coord.x + padding - minHeadX);
            coord.y = Std.int(coord.y + padding - minHeadY);
        }

        return {boardWidth:boardWidth, headCoords:coords};
    }
}
