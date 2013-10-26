package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.BiteAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

typedef BiteConfig = {
    var minReach:Int;
    var maxReach:Int;
    var maxSizeReference:Int;
    var baseReachOnThickness:Bool;
    var omnidirectional:Bool;
    var biteThroughCavities:Bool;
    var biteHeads:Bool;
    var orthoOnly:Bool;
    var startingBites:Int;
}

typedef BiteMove = {>Move,
    var targetNode:Int;
    var bitNodes:Array<Int>;
    var thickness:Int;
    var duplicate:Bool;
}

class BiteRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BiteAspect.NUM_BITES) var numBites_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var cfg:BiteConfig;
    private var biteMoves:Array<BiteMove>;

    public function new(cfg:BiteConfig):Void {
        super();
        this.cfg = cfg;
    }

    override private function _prime():Void {
        for (player in eachPlayer()) player[numBites_] = cfg.startingBites;
    }

    override private function _update():Void {

        biteMoves = [];

        // get current player head
        var currentPlayer:Int = state.aspects[currentPlayer_];

        var headIDs:Array<Int> = [];
        for (player in eachPlayer()) headIDs.push(player[head_]);

        var player = getPlayer(currentPlayer);
        if (player[numBites_] > 0) {

            var totalArea:Int = player[totalArea_];
            var bodyNode:BoardNode = getNode(player[bodyFirst_]);
            var body:Array<BoardNode> = bodyNode.boardListToArray(state.nodes, bodyNext_);
            var frontNodes:Array<BoardNode> = body.filter(isFront.bind(headIDs));

            // Grab the valid bites from immediate neighbors

            var newMoves:Array<BiteMove> = [];
            for (node in frontNodes) {
                for (neighbor in neighborsFor(node)) {
                    if (isValidEnemy(headIDs, currentPlayer, neighbor)) {
                        var move:BiteMove = generateMove(getID(node.value), [getID(neighbor.value)]);
                        if (!cfg.omnidirectional && cfg.baseReachOnThickness) {
                            // The baseReachOnThickness config param uses this data to determine how far to extend a bite
                            var backwards:Int = (node.neighbors.indexOf(neighbor) + 4) % 8;
                            var depth:Int = 0;
                            for (innerNode in node.walk(backwards)) {
                                if (innerNode.value[occupier_] == currentPlayer) depth++;
                                else break;
                            }
                            move.thickness = depth;
                        }
                        newMoves.push(move);
                    }
                }
            }
            for (ike in 0...newMoves.length) newMoves[ike].id = ike;
            biteMoves = newMoves.copy();

            // Extend the existing valid bites

            var reachItr:Int = 1;
            var growthPercent:Float = Math.min(1, totalArea / cfg.maxSizeReference); // The "size calculation" for players
            var reach:Int = Std.int(cfg.minReach + growthPercent * (cfg.maxReach - cfg.minReach));
            if (cfg.baseReachOnThickness) reach = cfg.maxReach;

            // We find moves by taking existing moves and extending them until there's nothing left to extend
            while (reachItr < reach && newMoves.length > 0) {
                var oldMoves:Array<BiteMove> = newMoves;
                newMoves = [];

                for (move in oldMoves) {
                    if (cfg.omnidirectional) {
                        // Omnidirectional moves are squiggly
                        for (bitNodeID in move.bitNodes) {
                            var bitNode:BoardNode = getNode(bitNodeID);
                            for (neighbor in neighborsFor(bitNode)) {
                                if (isValidEnemy(headIDs, currentPlayer, neighbor) && !move.bitNodes.has(getID(neighbor.value))) {
                                    newMoves.push(generateMove(move.targetNode, move.bitNodes.concat([getID(neighbor.value)]), move));
                                }
                            }
                        }
                    } else if (!cfg.baseReachOnThickness || move.bitNodes.length < move.thickness) {
                        // Straight moves are a little easier to generate
                        var firstBitNode:BoardNode = getNode(move.bitNodes[0]);
                        var lastBitNode:BoardNode = getNode(move.bitNodes[move.bitNodes.length - 1]);
                        var direction:Int = getNode(move.targetNode).neighbors.indexOf(firstBitNode);
                        var neighbor:BoardNode = lastBitNode.neighbors[direction];
                        if (isValidEnemy(headIDs, currentPlayer, neighbor)) {
                            var nextMove:BiteMove = generateMove(move.targetNode, move.bitNodes.concat([getID(neighbor.value)]), move);
                            nextMove.thickness = move.thickness;
                            newMoves.push(nextMove);
                        }
                    }
                }

                for (ike in 0...newMoves.length) newMoves[ike].id = ike + biteMoves.length;
                biteMoves = biteMoves.concat(newMoves);

                reachItr++;
            }
        }

        // We find all moves that represent the same action and mark the duplicates
        // (This helps AI players)
        for (ike in 0...biteMoves.length) {
            var biteMove:BiteMove = biteMoves[ike];
            if (biteMove.duplicate) continue;
            for (jen in ike + 1...biteMoves.length) {
                if (biteMoves[jen].duplicate) continue;
                biteMoves[jen].duplicate = movesAreEqual(biteMove, biteMoves[jen]);
            }
        }

        //trace('\n' + biteMoves.join('\n'));

        moves = cast biteMoves;
    }

    override private function _chooseMove(choice:Int):Void {

        var move:BiteMove = cast moves[choice];

        if (move.targetNode != Aspect.NULL) {

            // Grab data from the move

            var node:BoardNode = getNode(move.targetNode);
            var currentPlayer:Int = state.aspects[currentPlayer_];

            var maxFreshness:Int = state.aspects[maxFreshness_] + 1;
            var numBites:Int = getPlayer(currentPlayer)[numBites_] - 1;

            // Find the cells removed from each player

            var bitNodesByPlayer:Array<Array<BoardNode>> = [];
            for (player in eachPlayer()) bitNodesByPlayer.push([]);

            for (bitNodeID in move.bitNodes) {
                var bitNode:BoardNode = getNode(bitNodeID);
                bitNodesByPlayer[bitNode.value[occupier_]].push(bitNode);
            }

            // Remove the appropriate cells from each player

            for (player in eachPlayer()) {
                var bitNodes:Array<BoardNode> = bitNodesByPlayer[getID(player)];
                var bodyFirst:Int = player[bodyFirst_];
                for (node in bitNodes) bodyFirst = killCell(node, maxFreshness++, bodyFirst);
                player[bodyFirst_] = bodyFirst;
            }

            state.aspects[maxFreshness_] = maxFreshness;
            getPlayer(currentPlayer)[numBites_] = numBites;
        }
    }

    // "front" as in "battle front". Areas where the current player touches other players
    inline function isFront(headIDs:Array<Int>, node:BoardNode):Bool {
        return neighborsFor(node).exists(isValidEnemy.bind(headIDs, node.value[occupier_]));
    }

    // Depending on the config, enemy nodes of different kinds can be bitten
    inline function isValidEnemy(headIDs:Array<Int>, allegiance:Int, node:BoardNode):Bool {
        var val:Bool = true;
        if (node.value[occupier_] == allegiance) val = false; // Can't be the current player
        else if (node.value[occupier_] == Aspect.NULL) val = false; // Can't be the current player
        else if (!cfg.biteThroughCavities && node.value[isFilled_] == Aspect.FALSE) val = false; // Must be filled, or must allow biting through a cavity
        else if (!cfg.biteHeads && headIDs.has(getID(node.value))) val = false;

        return val;
    }

    inline function generateMove(targetNodeID:Int, bitNodes:Array<Int>, relatedMove:BiteMove = null):BiteMove {
        var move:BiteMove = {
            id:-1,
            targetNode:targetNodeID,
            bitNodes:bitNodes,
            relatedID:(relatedMove == null ? null : relatedMove.id),
            thickness:1,
            duplicate:false,
        };

        return move;
    }

    // compares the bit nodes of two moves; if they're the same, then the moves have the same consequence
    inline function movesAreEqual(move1:BiteMove, move2:BiteMove):Bool {
        var val:Bool = true;
        if (move1.bitNodes.length != move2.bitNodes.length) val = false;
        else for (bitNode in move1.bitNodes) if (!move2.bitNodes.has(bitNode)) { val = false; break; }
        return val;
    }

    inline function killCell(node:BoardNode, freshness:Int, firstIndex:Int):Int {
        if (node.value[isFilled_] == Aspect.TRUE) {
            var nextNode:BoardNode = node.removeNode(state.nodes, bodyNext_, bodyPrev_);
            if (firstIndex == getID(node.value)) firstIndex = nextNode == null ? Aspect.NULL : getID(nextNode.value);
            node.value[isFilled_] = Aspect.FALSE;
        }

        node.value[occupier_] = Aspect.NULL;
        node.value[freshness_] = freshness;

        return firstIndex;
    }

    inline function neighborsFor(node:BoardNode):Array<BoardNode> {
        return cfg.orthoOnly ? node.orthoNeighbors() : node.allNeighbors();
    }
}
