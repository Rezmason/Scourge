package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.GridNode;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

typedef XY = {x:Float, y:Float};

typedef BuildBoardConfig = {
    public var buildCfg:BuildConfig;
    public var circular:Bool;
    public var initGrid:String;
}

class BuildBoardRule extends Rule {

    // Creates boards for "skirmish games"

    private  static var PLAYER_DIST:Int = 9;
    private inline static var RIM:Int = 1;
    private inline static var PADDING:Int = 5 + RIM;
    private inline static var START_ANGLE:Float = 0.75;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    private var cfg:BuildBoardConfig;

    var nodeAspectTemplate:AspectSet;

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(IdentityAspect.NODE_ID) var nodeID_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(IdentityAspect.PLAYER_ID) var playerID_;

    public function new(cfg:BuildBoardConfig):Void {
        super();
        demiurgic = true;
        this.cfg = cfg;
    }

    override private function _prime():Void {

        nodeAspectTemplate = plan.nodeAspectTemplate.copy();

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var numPlayers:Int = numPlayers();
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

        var grid:BoardNode = makeSquareGraph(boardWidth);
        var hasInitGrid:Bool = cfg.initGrid != null && cfg.initGrid.length > 0;
        obstructGraphRim(grid);
        if (cfg.circular) encircleGraph(grid, boardWidth * 0.5 - RIM);
        if (hasInitGrid) initGraph(grid, cfg.initGrid, boardWidth);
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

    inline function makeNode():BoardNode {
        var node:BoardNode = new BoardNode(buildAspectSet(nodeAspectTemplate));
        node.value.mod(nodeID_, numNodes());
        state.nodes.push(node);

        var histAspects:AspectSet = buildHistAspectSet(nodeAspectTemplate, cfg.buildCfg.history);
        var histNode:BoardNode = new BoardNode(histAspects);
        cfg.buildCfg.historyState.nodes.push(histNode);

        return node;
    }

    inline function makeSquareGraph(width:Int):BoardNode {

        // Make a connected grid of nodes with default values
        var node:BoardNode = makeNode();
        for (ike in 1...width) node = node.attach(makeNode(), Gr.e);

        var row:BoardNode = node.run(Gr.w);
        for (ike in 1...width) {
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
        return node.run(Gr.nw).run(Gr.n).run(Gr.w);
    }

    inline function obstructGraphRim(grid:BoardNode):Void {
        for (node in grid.walk(Gr.e)) node.value.mod(isFilled_, Aspect.TRUE);
        for (node in grid.walk(Gr.s)) node.value.mod(isFilled_, Aspect.TRUE);
        for (node in grid.run(Gr.s).walk(Gr.e)) node.value.mod(isFilled_, Aspect.TRUE);
        for (node in grid.run(Gr.e).walk(Gr.s)) node.value.mod(isFilled_, Aspect.TRUE);
    }

    inline function populateGraphHeads(grid:BoardNode, headCoords:Array<XY>, plantHeads:Bool):Void {
        // Identify and change the occupier of each head node

        for (ike in 0...headCoords.length) {
            var coord:XY = headCoords[ike];
            var head:BoardNode = grid.run(Gr.e, Std.int(coord.x)).run(Gr.s, Std.int(coord.y));
            if (plantHeads) {
                head.value.mod(isFilled_, Aspect.TRUE);
                head.value.mod(occupier_, ike);
                getPlayer(ike).mod(head_, head.value.at(nodeID_));
            } else if (head.value.at(isFilled_) == Aspect.TRUE && head.value.at(occupier_) == ike) {
                getPlayer(ike).mod(head_, head.value.at(nodeID_));
            }
        }
    }

    inline function encircleGraph(grid:BoardNode, radius:Float):Void {
        // Circular levels' cells are obstructed if they're too far from the board's center

        var y:Int = 0;
        for (row in grid.walk(Gr.s)) {
            var x:Int = 0;
            for (column in row.walk(Gr.e)) {
                if (column.value.at(isFilled_) == 0) {
                    var fx:Float = x - radius + 0.5 - RIM;
                    var fy:Float = y - radius + 0.5 - RIM;
                    var insideCircle:Bool = Math.sqrt(fx * fx + fy * fy) < radius;
                    if (!insideCircle) column.value.mod(isFilled_, 1);
                }
                x++;
            }
            y++;
        }
    }

    inline function initGraph(grid:BoardNode, initGrid:String, boardWidth:Int):Void {

        // Refer to the initGrid to assign initial values to nodes

        var initGridWidth:Int = boardWidth + 1;

        initGrid = INIT_GRID_CLEANER.replace(initGrid, '');

        var y:Int = 0;
        for (row in grid.walk(Gr.s)) {
            var x:Int = 0;
            for (column in row.walk(Gr.e)) {
                if (column.value.at(isFilled_) == Aspect.FALSE) {
                    var char:String = initGrid.charAt(y * initGridWidth + x + 1);
                    if (char != ' ') {
                        column.value.mod(isFilled_, Aspect.TRUE);
                        if (!NUMERIC_CHAR.match(char)) column.value.mod(occupier_, Aspect.NULL);
                        else column.value.mod(occupier_, Std.parseInt(char));
                    }
                }
                x++;
            }
            y++;
        }
    }

    inline function populateGraphBodies():Void {

        var bodies:Array<Array<BoardNode>> = [];
        for (player in eachPlayer()) bodies.push([]);

        for (node in eachNode()) {
            if (node.value.at(isFilled_) != Aspect.FALSE) {
                var occupier:Int = node.value.at(occupier_);
                if (occupier != Aspect.NULL) {
                    if (bodies[occupier] == null) throw 'A node is owned by a player that doesn\'t exist: $occupier';
                    else bodies[occupier].push(node);
                }
            }
        }

        for (player in eachPlayer()) {
            var body:Array<BoardNode> = bodies[player.at(playerID_)];
            if (body.length > 0) {
                var bodyFirstNode:BoardNode = body[0];
                player.mod(bodyFirst_, bodyFirstNode.value.at(nodeID_));
                body.chainByAspect(nodeID_, bodyNext_, bodyPrev_);
            }
        }
    }
}
