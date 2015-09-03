package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.PieceTypes;
import net.rezmason.scourge.game.TempParams;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.pointers.Pointers;

typedef PickPieceMove = {>Move,
    var hatIndex:Int;
    var pieceTableID:Int;
    var rotation:Int;
    var reflection:Int;
}

class PickPieceRule extends BaseRule<FullPickPieceParams> {

    private var allMoves:Array<PickPieceMove>;

    // This rule is surprisingly complex

    @card(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_;
    @card(PieceAspect.PIECE_HAT_PREV) var pieceHatPrev_;

    @card(PieceAspect.PIECE_NEXT) var pieceNext_;
    @card(PieceAspect.PIECE_PREV) var piecePrev_;

    @card(PieceAspect.PIECE_OPTION_ID) var pieceMoveID_;

    @global(PieceAspect.PIECES_PICKED) var piecesPicked_;
    @global(PieceAspect.PIECE_FIRST) var pieceFirst_;
    @global(PieceAspect.PIECE_HAT_FIRST) var pieceHatFirst_;
    @global(PieceAspect.PIECE_REFLECTION) var pieceReflection_;
    @global(PieceAspect.PIECE_ROTATION) var pieceRotation_;
    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;

    @global(PieceAspect.PIECE_HAT_PLAYER) var pieceHatPlayer_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    // All this for an overglorified random piece picker!

    override private function _prime():Void {
        if (params.hatSize > params.pieceTableIDs.length) params.hatSize = params.pieceTableIDs.length;
        buildPieceMoves();
        buildHat();
    }

    override private function _update():Void {
        if (remakeHat()) {
            // The hat's been refilled; all piece moves are available as moves
            moves = cast allMoves.copy();
        } else if (state.global[pieceTableID_] == NULL) {
            // Iterate over the hat's contents and include the corresponding moves
            moves = [];
            var firstHatPiece:AspectSet = getCard(state.global[pieceHatFirst_]);
            var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.cards, pieceHatNext_);
            for (piece in hatPieces) moves.push(allMoves[piece[pieceMoveID_]]);
        } else {
            moves = [];
        }
    }

    override private function _chooseMove(choice:Int):Void {
        var move:PickPieceMove = cast moves[choice];
        if (remakeHat()) buildHat();
        pickMoveFromHat(move);
        setPiece(move.pieceTableID, move.reflection, move.rotation);
    }

    private function buildPieceMoves():Void {

        // Every move has to be made before the game begins. These moves
        // are reused throughout the game to represent the hat's contents.

        allMoves = [];
        
        // We create the table of piece frequencies from the params

        var pieceFrequencies:Array<Null<Int>> = [];
        for (pieceTableID in params.pieceTableIDs) {
            if (pieceFrequencies[pieceTableID] == null) pieceFrequencies[pieceTableID] = 0;
            pieceFrequencies[pieceTableID]++;
        }

        // Create an move for every element being picked randomly

        for (pieceTableID in 0...pieceFrequencies.length) {
            var freq:Null<Int> = pieceFrequencies[pieceTableID];
            if (freq == 0 || freq == null) continue;

            var freePiece:FreePiece = params.pieces.getPieceById(pieceTableID);
            var numRotations = freePiece.numRotations;

            // A piece that can't be flipped or rotated has its multiple symmetries
            // added to the hat, and so it has more moves

            if (params.allowFlipping) {
                if (params.allowRotating) {
                    generateMove(pieceTableID, 0, 0, freq);
                } else {
                    var spinWeight:Int = Std.int(numRotations / 4);
                    for (rotation in 0...numRotations) generateMove(pieceTableID, 0, rotation, freq * spinWeight);
                }
            } else {
                for (flip in 0...freePiece.numReflections) {
                    if (params.allowRotating) {
                        generateMove(pieceTableID, flip, 0, freq);
                    } else {
                        var spinWeight:Int = Std.int(numRotations / 4);
                        for (rotation in 0...numRotations) generateMove(pieceTableID, flip, rotation, freq * spinWeight);
                    }
                }
            }
        }

        // Create a hat card for every move
        var allPieces:Array<AspectSet> = [];
        for (move in allMoves) {
            move.hatIndex = numCards();
            var piece:AspectSet = addCard();
            piece[pieceMoveID_] = move.id;
            allPieces.push(piece);
        }

        allPieces.chainByAspect(ident_, pieceNext_, piecePrev_);
        state.global[pieceFirst_] = getID(allPieces[0]);
    }

    private function generateMove(pieceTableID:Int, reflection:Int, rotation:Int, weight:Int):PickPieceMove {
        var move:PickPieceMove = {
            pieceTableID:pieceTableID,
            rotation:rotation,
            reflection:reflection,
            weight:weight,
            relatedID:0,
            id:allMoves.length,
            hatIndex:0,
        };
        allMoves.push(move);
        return move;
    }

    private function setPiece(pieceTableID:Int, reflection:Int, rotation:Int):Void {
        state.global[pieceTableID_] = pieceTableID;
        state.global[pieceReflection_] = reflection;
        state.global[pieceRotation_] = rotation;
    }

    private function pickMoveFromHat(move:PickPieceMove):PickPieceMove {
        var firstHatPiece:AspectSet = getCard(state.global[pieceHatFirst_]);
        var pickedPiece:AspectSet = getCard(move.hatIndex);
        state.global[piecesPicked_] = state.global[piecesPicked_] + 1;

        var nextPiece:AspectSet = pickedPiece.removeSet(state.cards, pieceHatNext_, pieceHatPrev_);

        if (pickedPiece == firstHatPiece) {
            firstHatPiece = nextPiece;
            if (firstHatPiece == null) state.global[pieceHatFirst_] = NULL;
            else state.global[pieceHatFirst_] = getID(firstHatPiece);
        }

        return move;
    }

    private function buildHat():Void {
        var firstPiece:AspectSet = getCard(state.global[pieceFirst_]);
        var allPieces:Array<AspectSet> = firstPiece.listToArray(state.cards, pieceNext_);
        allPieces.chainByAspect(ident_, pieceHatNext_, pieceHatPrev_);
        state.global[pieceHatFirst_] = getID(firstPiece);
        state.global[piecesPicked_] = 0;
        state.global[pieceHatPlayer_] = state.global[currentPlayer_];
    }

    // We fill the hat up again if it's empty
    private function remakeHat():Bool {
        return state.global[pieceHatPlayer_] != state.global[currentPlayer_] ||
                state.global[piecesPicked_] == params.hatSize;
    }
}
