package net.rezmason.scourge.model;

import haxe.FastList;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.Aspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.IntHashUtils;

typedef XY = {x:Float, y:Float};
typedef BoardData = {boardWidth:Int, heads:Array<XY>};
typedef AspectRequirements = IntHash<Class<Aspect>>;

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

    public function makeState(cfg:BoardConfig):State {
        if (cfg == null) return null;

        var state:State = new State();

        var rules:Array<Rule> = cfg.rules;
        while (rules.has(null)) rules.remove(null);

        // Create and populate the aspect requirement lists
        var stateRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var boardRequirements:AspectRequirements = new AspectRequirements();

        boardRequirements.set(OwnershipAspect.id, OwnershipAspect);

        for (rule in rules) {
            stateRequirements.absorb(rule.listStateAspects());
            playerRequirements.absorb(rule.listPlayerAspects());
            boardRequirements.absorb(rule.listBoardAspects());
        }

        // Populate the game state with aspects, players and nodes
        createAspects(stateRequirements, state.aspects);
        for (genome in cfg.playerGenes) state.players.push(makePlayer(genome, playerRequirements));
        makeBoard(state.players, cfg.circular, cfg.initGrid, boardRequirements);

        return state;
    }

    function makeBoard(players:Array<PlayerState>, circular:Bool, initGrid:String, requirements:AspectRequirements):Void {
        var numPlayers:Int = players.length;

        // Derive the size of the board and the positions of the players' heads
        var data:BoardData = designBoard(numPlayers, PLAYER_DIST, PADDING + RIM);

        // Make a connected grid of nodes with default values
        var node:GridNode<IntHash<Aspect>> = makeNode(requirements);
        for (ike in 1...data.boardWidth) node = node.attach(makeNode(requirements), Gr.e);

        var row:GridNode<IntHash<Aspect>> = node.run(Gr.w);
        for (ike in 1...data.boardWidth) {
            for (column in row.walk(Gr.e)) {
                var next:GridNode<IntHash<Aspect>> = makeNode(requirements);
                column.attach(next, Gr.s);
                next.attach(column.w(), Gr.nw);
                next.attach(column.e(), Gr.ne);
                next.attach(column.sw(), Gr.w);
            }
            row = row.s();
        }

        // run to the northwest
        var grid:GridNode<IntHash<Aspect>> = node.run(Gr.nw).run(Gr.n).run(Gr.w);

        // obstruct the rim
        for (node in grid.walk(Gr.e)) nodeOwner(node).isFilled = 1;
        for (node in grid.walk(Gr.s)) nodeOwner(node).isFilled = 1;
        for (node in grid.run(Gr.s).walk(Gr.e)) nodeOwner(node).isFilled = 1;
        for (node in grid.run(Gr.e).walk(Gr.s)) nodeOwner(node).isFilled = 1;

        // Identify and change the occupier of each head node
        for (ike in 0...numPlayers) {
            var player:PlayerState = players[ike];
            var coord:XY = data.heads[ike];
            player.head = grid.run(Gr.e, coord.x.int()).run(Gr.s, coord.y.int());
            var ownerAspect:OwnershipAspect = nodeOwner(player.head);
            ownerAspect.isFilled = 1;
            ownerAspect.occupier = ike;
        }

        // Circular levels' cells are obstructed if they're too far from the board's center
        // Note: This creates lots of nodes whose states never change...

        if (circular) {
            var radius:Float = (data.boardWidth - RIM * 2) * 0.5;
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

        if (initGrid != null && initGrid.length > 0) {

            var initGridWidth:Int = data.boardWidth + 1;

            initGrid = INIT_GRID_CLEANER.replace(initGrid, "");

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
                            else ownerAspect.occupier = Std.int(Math.min(Std.parseInt(char), numPlayers));
                        }
                    }
                    x++;
                }
                y++;
            }
        }
    }

    inline function makePlayer(genome:String, requirements:AspectRequirements):PlayerState {
        var playerState:PlayerState = new PlayerState();
        playerState.genome = genome;
        createAspects(requirements, playerState.aspects);
        return playerState;
    }

    inline function makeNode(aspects:AspectRequirements):GridNode<IntHash<Aspect>> {
        return new GridNode<IntHash<Aspect>>(createAspects(aspects));
    }

    inline function nodeOwner(node:GridNode<IntHash<Aspect>>):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }

    inline function createAspects(requirements:AspectRequirements, hash:IntHash<Aspect> = null):IntHash<Aspect> {
        if (hash == null) hash = new IntHash<Aspect>();
        for (key in requirements.keys()) hash.set(key, Type.createInstance(requirements.get(key), []));
        return hash;
    }

    function designBoard(numHeads:Int, playerDistance:Float, padding:Float):BoardData {

        // Players' heads are spaced evenly apart from one another along the perimeter of a circle.
        // Player 1's head is at a 45 degree angle

        var startAngle:Float = 0.75;
        var headAngle:Float = 2 / numHeads;
        var boardRadius:Float = (numHeads == 1) ? 0 : playerDistance / (2 * Math.sin(Math.PI * headAngle * 0.5));

        var minHeadX:Float = boardRadius * 2 + 1;
        var maxHeadX:Float = -1;
        var minHeadY:Float = boardRadius * 2 + 1;
        var maxHeadY:Float = -1;

        var coords:Array<XY> = [];

        // First, find the bounds of the rectangle containing all heads as if they were arranged on a circle

        for (ike in 0...numHeads) {
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

        // For some values of numHeads, the heads will be relatively evenly spaced
        // but relatively unevenly positioned away from the edges of the board.
        // So we scale their positions to fit within a square.

        for (ike in 0...numHeads) {
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

        return {boardWidth:boardWidth, heads:coords};
    }
}
