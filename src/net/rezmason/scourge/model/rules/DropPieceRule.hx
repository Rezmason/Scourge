package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

typedef DropPieceConfig = {
    public var overlapSelf:Bool;
    public var pieceTableIDs:Array<Int>;
    public var allowFlipping:Bool;
    public var allowRotating:Bool;
    public var growGraph:Bool;
    public var allowNowhere:Bool;
    public var allowPiecePick:Bool; // if true, nothing in the game itself is left to chance
    public var orthoOnly:Bool;
    public var diagOnly:Bool;
    public var pieces:Pieces;
}

typedef DropPieceMove = {>Move,
    var targetNode:Int;
    var numAddedNodes:Int;
    var addedNodes:Map<Int, BoardLocus>;
    var pieceID:Int;
    var rotation:Int;
    var reflection:Int;
    var coord:IntCoord;
    var duplicate:Bool;
}

class DropPieceRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(PlyAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var cfg:DropPieceConfig;

    public function new(cfg:DropPieceConfig):Void {
        super();
        this.cfg = cfg;
    }

    override private function _update():Void {

        var dropMoves:Array<DropPieceMove> = [];

        // This allows the place-piece function to behave like a skip function
        // Setting this to false also forces players to forfeit if they can't place a piece
        if (cfg.allowNowhere) {
            var nowhereMove:DropPieceMove = {
                targetNode:Aspect.NULL,
                coord:null,
                pieceID:Aspect.NULL,
                rotation:0,
                reflection:0,
                id:0,
                duplicate:false,
                numAddedNodes:0,
                addedNodes:new Map(),
            };
            dropMoves.push(cast nowhereMove);
        }

        var pieceIDs:Array<Int> = [];
        if (cfg.allowPiecePick) for (pieceID in cfg.pieceTableIDs) pieceIDs.push(pieceID);
        else if (state.aspects[pieceTableID_] != Aspect.NULL) pieceIDs.push(state.aspects[pieceTableID_]);

        // get current player head
        var currentPlayer:Int = state.aspects[currentPlayer_];
        var bodyNode:BoardLocus = getNode(getPlayer(currentPlayer)[bodyFirst_]);

        // Find edge nodes of current player
        var edgeNodes:Array<BoardLocus> = bodyNode.boardListToArray(state.nodes, bodyNext_).filter(isFreeEdge);

        var pieceReflection:Int = state.aspects[pieceReflection_];
        var pieceRotation:Int = state.aspects[pieceRotation_];

        for (pieceID in pieceIDs) {

            var pieceGroup:PieceGroup = cfg.pieces.getPieceById(pieceID);

            // For each allowed reflection,
            var allowedReflectionIndex:Int = pieceReflection % pieceGroup.length;
            for (reflectionIndex in 0...pieceGroup.length) {

                if (!cfg.allowFlipping && reflectionIndex != allowedReflectionIndex) continue;
                var reflection:Array<Piece> = pieceGroup[reflectionIndex];

                // For each allowed rotation,
                var allowedRotationIndex:Int = pieceRotation % reflection.length;

                for (rotationIndex in 0...reflection.length) {

                    if (!cfg.allowRotating && rotationIndex != allowedRotationIndex) continue;
                    var rotation:Piece = reflection[rotationIndex];

                    // For each edge node,
                    for (node in edgeNodes) {

                        // Generate the piece's footprint

                        var footprint:Array<IntCoord> = [];
                        if (cfg.overlapSelf) footprint = footprint.concat(rotation[0]);
                        if (!cfg.diagOnly) footprint = footprint.concat(rotation[1]);
                        if (!cfg.orthoOnly) footprint = footprint.concat(rotation[2]);

                        // Using each footprint coord as a home coord (aka the point of connection),
                        for (homeCoord in footprint) {

                            // Is the piece's body clear?

                            var valid:Bool = true;

                            var numAddedNodes:Int = 0;
                            var addedNodes:Map<Int, BoardLocus> = new Map();

                            for (coord in rotation[0]) {
                                var nodeAtCoord:BoardLocus = walkNode(node, coord, homeCoord);
                                addedNodes[getID(nodeAtCoord.value)] = nodeAtCoord;
                                numAddedNodes++;
                                var occupier:Int = nodeAtCoord.value[occupier_];
                                var isFilled:Int = nodeAtCoord.value[isFilled_];

                                if (isFilled == Aspect.TRUE && !(cfg.overlapSelf && occupier == currentPlayer)) {
                                    valid = false;
                                    break;
                                }
                            }

                            if (valid) {
                                dropMoves.push({
                                    targetNode:getID(node.value),
                                    coord:homeCoord,
                                    pieceID:pieceID,
                                    rotation:rotationIndex,
                                    reflection:reflectionIndex,
                                    id:dropMoves.length,
                                    numAddedNodes:numAddedNodes,
                                    addedNodes:addedNodes,
                                    duplicate:false,
                                });
                            }
                        }
                    }
                }
            }
        }

        // We find and mark duplicate moves, to help AI players
        for (ike in 0...dropMoves.length) {
            var dropMove:DropPieceMove = dropMoves[ike];
            if (dropMove.duplicate) continue;
            for (jen in ike + 1...dropMoves.length) {
                if (dropMoves[jen].duplicate) continue;
                dropMoves[jen].duplicate = movesAreEqual(dropMove, dropMoves[jen]);
            }
        }

        moves = cast dropMoves;
    }

    override private function _chooseMove(choice:Int):Void {

        var move:DropPieceMove = cast moves[choice];

        var currentPlayer:Int = state.aspects[currentPlayer_];
        var player:AspectSet = getPlayer(currentPlayer);

        if (move.targetNode != Aspect.NULL) {
            var pieceGroup:PieceGroup = cfg.pieces.getPieceById(move.pieceID);
            var node:BoardLocus = getNode(move.targetNode);
            var coords:Array<IntCoord> = pieceGroup[move.reflection][move.rotation][0];
            var homeCoord:IntCoord = move.coord;
            var maxFreshness:Int = state.aspects[maxFreshness_] + 1;

            var bodyNode:BoardLocus = getNode(getPlayer(currentPlayer)[bodyFirst_]);

            for (coord in coords) bodyNode = fillAndOccupyCell(walkNode(node, coord, homeCoord), currentPlayer, maxFreshness, bodyNode);
            player[bodyFirst_] = getID(bodyNode.value);

            state.aspects[maxFreshness_] = maxFreshness;

            player[numConsecutiveSkips_] = 0;
        } else {
            player[numConsecutiveSkips_] = player[numConsecutiveSkips_] + 1;
        }

        state.aspects[pieceTableID_] = Aspect.NULL;
    }

    inline function isFreeEdge(node:BoardLocus):Bool {
        return neighborsFor(node, cfg.orthoOnly).exists(isVacant);
    }

    inline function isVacant(node:BoardLocus):Bool {
        return node.value[isFilled_] == Aspect.FALSE;
    }

    inline function movesAreEqual(move1:DropPieceMove, move2:DropPieceMove):Bool {
        var val:Bool = true;
        //if (move1.targetNode != move2.targetNode) val = false;
        if (move1.numAddedNodes != move2.numAddedNodes) val = false;
        else for (addedNodeID in move1.addedNodes.keys()) if (!move2.addedNodes.exists(addedNodeID)) { val = false; break; }
        return val;
    }

    inline function fillAndOccupyCell(node:BoardLocus, currentPlayer:Int, maxFreshness, bodyNode:BoardLocus):BoardLocus {
        var me:AspectSet = node.value;
        if (me[occupier_] != currentPlayer || me[isFilled_] == Aspect.FALSE) me[freshness_] = maxFreshness;
        me[occupier_] = currentPlayer;
        me[isFilled_] = Aspect.TRUE;
        return bodyNode.addNode(node, state.nodes, ident_, bodyNext_, bodyPrev_);
    }

    // A works-for-now function for translating piece coords into nodes accessible from a given starting point
    inline function walkNode(node:BoardLocus, fromCoord:IntCoord, toCoord:IntCoord):BoardLocus {
        var dn:Int = 0;
        var dw:Int = 0;
        var de:Int = toCoord[0] - fromCoord[0];
        var ds:Int = toCoord[1] - fromCoord[1];

        if (de < 0) {
            dw = -de;
            de = 0;
        }

        if (ds < 0) {
            dn = -ds;
            ds = 0;
        }

        return node.run(Gr.n, dn).run(Gr.s, ds).run(Gr.e, de).run(Gr.w, dw);
    }

    inline function neighborsFor(node:BoardLocus, ortho:Bool):Array<BoardLocus> {
        return ortho ? node.orthoNeighbors() : node.allNeighbors();
    }
}
