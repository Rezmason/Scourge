package net.rezmason.scourge.model;

import haxe.FastList;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.Aspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;

typedef XY = {x:Float, y:Float};
typedef BoardData = {boardWidth:Int, heads:Array<XY>};

class BoardStateFactory {

    // Creates boards for "skirmish games"
    // I suspect that this is actually a rule. Might refactor in the future

    private static var OWNERSHIP:Int = OwnershipAspect.id;
    private inline static var PLAYER_DIST:Int = 9;
    private inline static var PADDING:Int = 5;
    private inline static var RIM:Int = 1;

    private static var INIT_GRID_CLEANER:EReg = ~/(\n\t)/g;
    private static var NUMERIC_CHAR:EReg = ~/(\d)/g;

    public function new():Void {

    }

    public function makeState(cfg:BoardStateConfig):State {
        if (cfg == null) return null;

        var state:State = new State();

        var rules:Array<Rule> = cfg.rules;
        while (rules.has(null)) rules.remove(null);
        for (genome in cfg.playerGenes) state.players.push(makePlayer(genome, rules));
        for (rule in rules) rule.addGameAspects(state.aspects);

        makeBoard(state.players, cfg.circular, cfg.initGrid, rules);

        return state;
    }

    function makeBoard(players:Array<PlayerState>, circular:Bool, initGrid:String, rules:Array<Rule>):Void {
        var numPlayers:Int = players.length;

        // build the level out of nodes
        var data:BoardData = getHeadPoints(numPlayers, PLAYER_DIST, PADDING + RIM);

        // Make a connected grid of nodes with default values
        var node:GridNode<IntHash<Aspect>> = makeNode(rules);
        for (ike in 1...data.boardWidth) node = node.attach(makeNode(rules), Gr.e);

        var row:GridNode<IntHash<Aspect>> = node.run(Gr.w);
        for (ike in 1...data.boardWidth) {
            for (column in row.walk(Gr.e)) {
                var next:GridNode<IntHash<Aspect>> = makeNode(rules);
                column.attach(next, Gr.s);
                next.attach(column.w(), Gr.nw);
                next.attach(column.e(), Gr.ne);
                next.attach(column.sw(), Gr.w);
            }
            row = row.s();
        }

        // run to the northwest
        var grid:GridNode<IntHash<Aspect>> = node.run(Gr.nw).run(Gr.n).run(Gr.w);

        // obstruct the RIM
        for (node in grid.walk(Gr.e)) getOwner(node).isFilled.value = 1;
        for (node in grid.walk(Gr.s)) getOwner(node).isFilled.value = 1;
        for (node in grid.run(Gr.s).walk(Gr.e)) getOwner(node).isFilled.value = 1;
        for (node in grid.run(Gr.e).walk(Gr.s)) getOwner(node).isFilled.value = 1;

        // Identify and change the occupier of each head
        for (ike in 0...numPlayers) {
            var player:PlayerState = players[ike];
            var coord:XY = data.heads[ike];
            player.head = grid.run(Gr.e, coord.x.int()).run(Gr.s, coord.y.int());
            var ownerAspect:OwnershipAspect = getOwner(player.head);
            ownerAspect.isFilled.value = 1;
            ownerAspect.occupier.value = ike;
        }

        if (circular) {
            var radius:Float = (data.boardWidth - RIM * 2) * 0.5;
            var y:Int = 0;
            for (row in grid.walk(Gr.s)) {
                var x:Int = 0;
                for (column in row.walk(Gr.e)) {
                    var ownerAspect:OwnershipAspect = getOwner(column);
                    if (ownerAspect.isFilled.value == 0) {
                        var fx:Float = x - radius + 0.5 - RIM;
                        var fy:Float = y - radius + 0.5 - RIM;
                        var insideCircle:Bool = Math.sqrt(fx * fx + fy * fy) < radius;
                        if (!insideCircle) ownerAspect.isFilled.value = 1;
                    }
                    x++;
                }
                y++;
            }
        }

        if (initGrid != null && initGrid.length > 0) {

            var initGridWidth:Int = data.boardWidth + 1;

            initGrid = INIT_GRID_CLEANER.replace(initGrid, "");

            var y:Int = 0;
            for (row in grid.walk(Gr.s)) {
                var x:Int = 0;
                for (column in row.walk(Gr.e)) {
                    var ownerAspect:OwnershipAspect = getOwner(column);
                    if (ownerAspect.isFilled.value == 0) {
                        var char:String = initGrid.charAt(y * initGridWidth + x + 1);
                        if (char != " ") {
                            ownerAspect.isFilled.value = 1;
                            if (!NUMERIC_CHAR.match(char)) ownerAspect.occupier.value = -1;
                            else ownerAspect.occupier.value = Std.int(Math.min(Std.parseInt(char), numPlayers));
                        }
                    }
                    x++;
                }
                y++;
            }
        }
    }

    function makeNode(rules:Array<Rule>):GridNode<IntHash<Aspect>> {
        var node:GridNode<IntHash<Aspect>> = new GridNode<IntHash<Aspect>>();
        var cell:IntHash<Aspect> = new IntHash<Aspect>();
        cell.set(OWNERSHIP, new OwnershipAspect());
        for (rule in rules) rule.addCellAspects(cell);
        node.value = cell;
        return node;
    }

    inline function getOwner(node:GridNode<IntHash<Aspect>>):OwnershipAspect {
        return cast node.value.get(OWNERSHIP);
    }

    function getHeadPoints(numHeads:Int, playerDistance:Float, padding:Float):BoardData {

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

        var boardWidth:Int = Std.int(maxHeadX - minHeadX + 2 * padding);

        for (coord in coords) {
            coord.x = Std.int(coord.x + padding - minHeadX);
            coord.y = Std.int(coord.y + padding - minHeadY);
        }

        return {boardWidth:boardWidth, heads:coords};
    }

    function makePlayer(genome:String, rules:Array<Rule>):PlayerState {
        var playerState:PlayerState = new PlayerState();
        playerState.genome = genome;
        for (rule in rules) rule.addPlayerAspects(playerState.aspects);
        return playerState;
    }
}
