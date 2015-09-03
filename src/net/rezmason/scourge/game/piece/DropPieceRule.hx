package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.grid.GridDirection.*;
import net.rezmason.grid.Cell;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.PieceTypes;
import net.rezmason.scourge.game.TempParams;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.scourge.game.meta.SkipAspect;

using Lambda;
using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.pointers.Pointers;

typedef DropPieceMove = {>Move,
    var targetSpace:Int;
    var numAddedSpaces:Int;
    var addedSpaces:Array<Int>;
    var rotation:Int;
    var reflection:Int;
    var coord:IntCoord;
    var duplicate:Bool;
}

class DropPieceRule extends BaseRule<FullDropPieceParams> {

    @space(BodyAspect.BODY_NEXT) var bodyNext_;
    @space(BodyAspect.BODY_PREV) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS) var freshness_;
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(SkipAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;
    @global(PieceAspect.PIECE_REFLECTION) var pieceReflection_;
    @global(PieceAspect.PIECE_ROTATION) var pieceRotation_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var nowhereMove:DropPieceMove = makeMove();
    private var movePool:Array<DropPieceMove> = [];
    private var allMoves:Array<DropPieceMove> = [];

    override private function _update():Void {

        var dropMoves:Array<DropPieceMove> = [];

        // This allows the place-piece function to behave like a skip function
        // Setting this to false also forces players to forfeit if they can't place a piece
        if (params.allowSkipping) dropMoves.push(cast nowhereMove);

        
        // get current player head
        var currentPlayer:Int = state.global[currentPlayer_];
        var bodySpace:AspectSet = getSpace(getPlayer(currentPlayer)[bodyFirst_]);

        // Find edge spaces of current player
        var edgeSpaces:Array<AspectSet> = bodySpace.listToArray(state.spaces, bodyNext_).filter(hasFreeEdge);

        var pieceReflection:Int = state.global[pieceReflection_];
        var pieceRotation:Int = state.global[pieceRotation_];
        
        var pieceID:Int = state.global[pieceTableID_];

        if (pieceID != NULL) {

            var freePiece:FreePiece = params.pieces.getPieceById(pieceID);

            // For each allowed reflection,
            var allowedReflectionIndex:Int = pieceReflection % freePiece.numReflections;
            for (reflectionIndex in 0...freePiece.numReflections) {

                if (!params.allowFlipping && reflectionIndex != allowedReflectionIndex) continue;
                
                // For each allowed rotation,
                var allowedRotationIndex:Int = pieceRotation % freePiece.numRotations;

                for (rotationIndex in 0...freePiece.numRotations) {

                    if (!params.allowRotating && rotationIndex != allowedRotationIndex) continue;
                    var piece:Piece = freePiece.getPiece(reflectionIndex, rotationIndex);

                    // For each edge space,
                    for (space in edgeSpaces) {

                        // Generate the piece's footprint

                        var footprint = piece.footprint(params.dropOverlapsSelf, !params.dropDiagOnly, !params.dropOrthoOnly);

                        // Using each footprint coord as a home coord (aka the point of connection),
                        for (homeCoord in footprint) {

                            // Is the piece's body clear?

                            var valid:Bool = true;

                            var numAddedSpaces:Int = 0;
                            var addedSpaces:Array<Int> = [];

                            for (coord in piece.cells) {
                                var spaceAtCoord:AspectSet = walkCell(getSpaceCell(space), coord, homeCoord).value;
                                addedSpaces.push(getID(spaceAtCoord));
                                numAddedSpaces++;
                                var occupier:Int = spaceAtCoord[occupier_];
                                var isFilled:Int = spaceAtCoord[isFilled_];

                                if (isFilled == TRUE && !(params.dropOverlapsSelf && occupier == currentPlayer)) {
                                    valid = false;
                                    break;
                                }
                            }

                            if (valid) {
                                var dropMove:DropPieceMove = getMove();
                                dropMove.targetSpace = getID(space);
                                dropMove.coord = homeCoord;
                                dropMove.rotation = rotationIndex;
                                dropMove.reflection = reflectionIndex;
                                dropMove.id = dropMoves.length;
                                dropMove.numAddedSpaces = numAddedSpaces;
                                dropMove.addedSpaces = addedSpaces;
                                dropMove.duplicate = false;
                                dropMoves.push(dropMove);
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

    inline function getMove():DropPieceMove {
        var move:DropPieceMove = movePool.pop();
        if (move == null) {
            move = makeMove();
            allMoves.push(move);
        }
        return move;
    }

    inline static function makeMove():DropPieceMove {
        return {
            id:-1,
            targetSpace:NULL,
            reflection:-1,
            rotation:-1,
            numAddedSpaces:0,
            addedSpaces:null,
            coord:null,
            duplicate:false,
        };
    }

    override private function _chooseMove(choice:Int):Void {
        var move:DropPieceMove = cast moves[choice];
        var currentPlayer:Int = state.global[currentPlayer_];
        var player:AspectSet = getPlayer(currentPlayer);

        if (move.targetSpace != NULL) {
            var maxFreshness:Int = state.global[maxFreshness_];
            var bodySpace:AspectSet = getSpace(getPlayer(currentPlayer)[bodyFirst_]);
            for (id in move.addedSpaces) bodySpace = fillAndOccupyCell(getSpace(id), currentPlayer, maxFreshness, bodySpace);
            player[bodyFirst_] = getID(bodySpace);
            state.global[maxFreshness_] = maxFreshness + 1;
            player[numConsecutiveSkips_] = 0;
        } else {
            player[numConsecutiveSkips_] = player[numConsecutiveSkips_] + 1;
        }

        state.global[pieceTableID_] = NULL;
        signalChange();
    }

    override private function _collectMoves():Void movePool = allMoves.copy();

    inline function hasFreeEdge(space:AspectSet):Bool {
        var exists:Bool = false;

        for (neighbor in neighborsFor(getSpaceCell(space), params.dropOrthoOnly)) {
            if (neighbor.value[isFilled_] == FALSE) {
                exists = true;
                break;
            }
        }

        return exists;
    }

    inline function movesAreEqual(move1:DropPieceMove, move2:DropPieceMove):Bool {
        var val:Bool = true;
        //if (move1.targetSpace != move2.targetSpace) val = false;
        if (move1.numAddedSpaces != move2.numAddedSpaces) {
            val = false;
        } else {
            for (addedSpaceID1 in move1.addedSpaces) {
                for (addedSpaceID2 in move2.addedSpaces) {
                    if (addedSpaceID1 == addedSpaceID2) {
                        val = false;
                        break;
                    }
                    if (!val) break;
                }
            }
        }
        return val;
    }

    inline function fillAndOccupyCell(me:AspectSet, currentPlayer:Int, maxFreshness, bodySpace:AspectSet):AspectSet {
        if (me[occupier_] != currentPlayer || me[isFilled_] == FALSE) me[freshness_] = maxFreshness;
        me[occupier_] = currentPlayer;
        me[isFilled_] = TRUE;
        return bodySpace.addSet(me, state.spaces, ident_, bodyNext_, bodyPrev_);
    }

    // A works-for-now function for translating piece coords into spaces accessible from a given starting point
    inline function walkCell(cell:BoardCell, fromCoord:IntCoord, toCoord:IntCoord):BoardCell {
        var dn:Int = 0;
        var dw:Int = 0;
        var de:Int = toCoord.x - fromCoord.x;
        var ds:Int = toCoord.y - fromCoord.y;

        if (de < 0) {
            dw = -de;
            de = 0;
        }

        if (ds < 0) {
            dn = -ds;
            ds = 0;
        }

        return cell.run(N, dn).run(S, ds).run(E, de).run(W, dw);
    }

    inline function neighborsFor(cell:BoardCell, ortho:Bool):Array<BoardCell> {
        return ortho ? cell.orthoNeighbors() : cell.neighbors;
    }
}
