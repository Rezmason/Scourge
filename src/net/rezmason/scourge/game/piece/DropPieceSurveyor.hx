package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Surveyor;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.Piece;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.aspect.AspectUtils;

class DropPieceSurveyor extends Surveyor<DropPieceParams> {

    @space(BodyAspect.BODY_NEXT) var bodyNext_;
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @global(PieceAspect.PIECE_TABLE_INDEX) var pieceTableIndex_;
    @global(PieceAspect.PIECE_REFLECTION) var pieceReflection_;
    @global(PieceAspect.PIECE_ROTATION) var pieceRotation_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var nowhereMove:DropPieceMove = makeMove();
    private var movePool:Array<DropPieceMove> = [];
    private var allMoves:Array<DropPieceMove> = [];

    override public function update():Void {

        var dropMoves:Array<DropPieceMove> = [];

        // This allows the place-piece function to behave like a skip function
        // Setting this to false also forces players to forfeit if they can't place a piece
        if (params.allowSkipping) dropMoves.push(cast nowhereMove);

        
        // get current player head
        var currentPlayer:Int = state.global[currentPlayer_];
        var bodySpace = getSpace(getPlayer(currentPlayer)[bodyFirst_]);

        // Find edge spaces of current player
        var edgeSpaces = bodySpace.listToArray(state.spaces, bodyNext_).filter(hasFreeEdge);

        var pieceReflection:Int = state.global[pieceReflection_];
        var pieceRotation:Int = state.global[pieceRotation_];
        
        var pieceTableIndex:Int = state.global[pieceTableIndex_];

        if (pieceTableIndex != NULL) {

            var freePiece:Piece = params.pieceLib.getPieceByID(params.pieceIDs[pieceTableIndex]);

            // For each allowed reflection,
            var allowedReflectionIndex:Int = pieceReflection % freePiece.numReflections;
            for (reflectionIndex in 0...freePiece.numReflections) {

                if (!params.allowFlipping && reflectionIndex != allowedReflectionIndex) continue;
                
                // For each allowed rotation,
                var allowedRotationIndex:Int = pieceRotation % freePiece.numRotations;

                for (rotationIndex in 0...freePiece.numRotations) {

                    if (!params.allowRotating && rotationIndex != allowedRotationIndex) continue;
                    var piece:Piece = freePiece.getVariant(reflectionIndex, rotationIndex);

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
                                var dx = coord.x - homeCoord.x;
                                var dy = coord.y - homeCoord.y;
                                var spaceAtCoord = getSpaceCell(space).runEuclidean(dx, dy).value;

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

    override public function collectMoves():Void movePool = allMoves.copy();

    inline function hasFreeEdge(space) {
        var exists = false;
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

    inline function neighborsFor(cell:BoardCell, ortho:Bool):Array<BoardCell> {
        return ortho ? cell.orthoNeighbors() : cell.neighbors;
    }
}
