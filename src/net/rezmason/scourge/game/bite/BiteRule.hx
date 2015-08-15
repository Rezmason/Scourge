package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

typedef BiteMove = {>Move,
    var targetNode:Int;
    var bitNodes:Array<Int>;
    var thickness:Int;
    var duplicate:Bool;
}

class BiteRule extends BaseRule<BiteParams> {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BiteAspect.NUM_BITES) var numBites_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var movePool:Array<BiteMove> = [];
    private var allMoves:Array<BiteMove> = [];

    override private function _prime():Void {
        for (player in eachPlayer()) player[numBites_] = params.startingBites;
    }

    override private function _update():Void {

        var biteMoves:Array<BiteMove> = [];

        // get current player head
        var currentPlayer:Int = state.global[currentPlayer_];

        var headIDs:Array<Int> = [];
        for (player in eachPlayer()) headIDs.push(player[head_]);

        var player = getPlayer(currentPlayer);
        if (player[numBites_] > 0) {

            var totalArea:Int = player[totalArea_];
            var bodyNode:AspectSet = getNode(player[bodyFirst_]);
            var body:Array<AspectSet> = bodyNode.listToArray(state.nodes, bodyNext_);
            var frontNodes:Array<AspectSet> = body.filter(isFront.bind(headIDs));

            // Grab the valid bites from immediate neighbors

            var newMoves:Array<BiteMove> = [];
            for (node in frontNodes) {
                var cell:BoardCell = getNodeCell(node);
                for (neighbor in neighborsFor(cell)) {
                    if (isValidEnemy(headIDs, currentPlayer, neighbor.value)) {
                        var move:BiteMove = getMove(getID(node), [getID(neighbor.value)]);
                        if (!params.omnidirectional && params.baseReachOnThickness) {
                            // The baseReachOnThickness params param uses this data to determine how far to extend a bite
                            var backwards:Int = (cell.neighbors.indexOf(neighbor) + 4) % 8;
                            var depth:Int = 0;
                            for (innerNode in cell.walk(backwards)) {
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
            var growthPercent:Float = Math.min(1, totalArea / params.maxSizeReference); // The "size calculation" for players
            var reach:Int = Std.int(params.minReach + growthPercent * (params.maxReach - params.minReach));
            if (params.baseReachOnThickness) reach = params.maxReach;

            // We find moves by taking existing moves and extending them until there's nothing left to extend
            while (reachItr < reach && newMoves.length > 0) {
                var oldMoves:Array<BiteMove> = newMoves;
                newMoves = [];

                for (move in oldMoves) {
                    if (params.omnidirectional) {
                        // Omnidirectional moves are squiggly
                        for (bitNodeID in move.bitNodes) {
                            var bitCell:BoardCell = getCell(bitNodeID);
                            for (neighbor in neighborsFor(bitCell)) {
                                if (isValidEnemy(headIDs, currentPlayer, neighbor.value) && move.bitNodes.indexOf(getID(neighbor.value)) == -1) {
                                    newMoves.push(getMove(move.targetNode, move.bitNodes.concat([getID(neighbor.value)]), move));
                                }
                            }
                        }
                    } else if (!params.baseReachOnThickness || move.bitNodes.length < move.thickness) {
                        // Straight moves are a little easier to generate
                        var firstBitCell:BoardCell = getCell(move.bitNodes[0]);
                        var lastBitCell:BoardCell = getCell(move.bitNodes[move.bitNodes.length - 1]);
                        var direction:Int = getCell(move.targetNode).neighbors.indexOf(firstBitCell);
                        var neighbor:BoardCell = lastBitCell.neighbors[direction];
                        if (isValidEnemy(headIDs, currentPlayer, neighbor.value)) {
                            var nextMove:BiteMove = getMove(move.targetNode, move.bitNodes.concat([getID(neighbor.value)]), move);
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

        if (move.targetNode != NULL) {

            // Grab data from the move

            var currentPlayer:Int = state.global[currentPlayer_];

            var maxFreshness:Int = state.global[maxFreshness_];
            var numBites:Int = getPlayer(currentPlayer)[numBites_] - 1;

            // Find the cells removed from each player

            var bitNodesByPlayer:Array<Array<AspectSet>> = [];
            for (player in eachPlayer()) bitNodesByPlayer.push([]);

            for (bitNodeID in move.bitNodes) {
                var bitNode:AspectSet = getNode(bitNodeID);
                bitNodesByPlayer[bitNode[occupier_]].push(bitNode);
            }

            // Remove the appropriate cells from each player

            for (player in eachPlayer()) {
                var bitNodes:Array<AspectSet> = bitNodesByPlayer[getID(player)];
                var bodyFirst:Int = player[bodyFirst_];
                for (bitNode in bitNodes) bodyFirst = killCell(bitNode, maxFreshness++, bodyFirst);
                player[bodyFirst_] = bodyFirst;
            }

            state.global[maxFreshness_] = maxFreshness;
            getPlayer(currentPlayer)[numBites_] = numBites;
        }

        signalChange();
    }

    override private function _collectMoves():Void movePool = allMoves.copy();

    // "front" as in "battle front". Areas where the current player touches other players
    /*
    inline function isFront(headIDs:Array<Int>, node:AspectSet):Bool {
        return neighborsFor(getNodeCell(node)).isNotNull(isValidEnemy.bind(headIDs, node[occupier_]));
    }
    */

    inline function isFront(headIDs:Array<Int>, node:AspectSet):Bool {
        var isNotNull:Bool = false;

        var occupier:Int = node[occupier_];

        for (neighbor in neighborsFor(getNodeCell(node))) {
            if (isValidEnemy(headIDs, occupier, neighbor.value)) {
                isNotNull = true;
                break;
            }
        }

        return isNotNull;
    }

    // Depending on the params, enemy nodes of different kinds can be bitten
    inline function isValidEnemy(headIDs:Array<Int>, allegiance:Int, node:AspectSet):Bool {
        var val:Bool = true;
        if (node[occupier_] == allegiance) val = false; // Can't be the current player
        else if (node[occupier_] == NULL) val = false; // Can't be the current player
        else if (!params.biteThroughCavities && node[isFilled_] == FALSE) val = false; // Must be filled, or must allow biting through a cavity
        else if (!params.biteHeads && headIDs.indexOf(getID(node)) != -1) val = false;

        return val;
    }

    inline function getMove(targetNodeID:Int, bitNodes:Array<Int>, relatedMove:BiteMove = null):BiteMove {

        var relatedID:Null<Int> = (relatedMove == null ? null : relatedMove.id);

        var move:BiteMove = movePool.pop();
        if (move == null) {
            move = {id:-1, targetNode:targetNodeID, bitNodes:bitNodes, relatedID:null, thickness:1, duplicate:false};
            allMoves.push(move);
        } else {
            move.id = -1;
            move.targetNode = targetNodeID;
            move.bitNodes = bitNodes;
            move.relatedID = relatedID;
            move.thickness = 1;
            move.duplicate = false;
        }

        return move;
    }

    // compares the bit nodes of two moves; if they're the same, then the moves have the same consequence
    inline function movesAreEqual(move1:BiteMove, move2:BiteMove):Bool {
        var val:Bool = true;
        if (move1.bitNodes.length != move2.bitNodes.length) val = false;
        else for (bitNode in move1.bitNodes) if (move2.bitNodes.indexOf(bitNode) == -1) { val = false; break; }
        return val;
    }

    inline function killCell(node:AspectSet, freshness:Int, firstIndex:Int):Int {
        if (node[isFilled_] == TRUE) {
            var nextNode:AspectSet = node.removeSet(state.nodes, bodyNext_, bodyPrev_);
            if (firstIndex == getID(node)) firstIndex = nextNode == null ? NULL : getID(nextNode);
            node[isFilled_] = FALSE;
        }

        node[occupier_] = NULL;
        node[freshness_] = freshness;

        return firstIndex;
    }

    inline function neighborsFor(node:BoardCell):Array<BoardCell> {
        return params.orthoOnly ? node.orthoNeighbors() : node.neighbors;
    }
}
