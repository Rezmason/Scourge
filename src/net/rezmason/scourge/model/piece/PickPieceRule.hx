package net.rezmason.scourge.model.piece;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.meta.PlyAspect;

using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.Pointers;

typedef PickPieceMove = {>Move,
    var hatIndex:Int;
    var pieceTableID:Int;
    var rotation:Int;
    var reflection:Int;
}

class PickPieceRule extends RopesRule<PickPieceParams> {

    static var stateReqs:AspectRequirements;

    private var allMoves:Array<PickPieceMove>;
    private var pickMove:Move;

    // This rule is surprisingly complex

    @extra(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_;
    @extra(PieceAspect.PIECE_HAT_PREV) var pieceHatPrev_;

    @extra(PieceAspect.PIECE_NEXT) var pieceNext_;
    @extra(PieceAspect.PIECE_PREV) var piecePrev_;

    @extra(PieceAspect.PIECE_OPTION_ID) var pieceMoveID_;

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
            // The hat's been refilled; all piece moves are available as quantum moves
            moves = [pickMove];
            quantumMoves = cast allMoves.copy();
        } else if (state.global[pieceTableID_] == NULL) {
            moves = [pickMove];

            // Iterate over the hat's contents and include the corresopnding quantum moves

            var quantumPieceMoves:Array<PickPieceMove> = [];
            var firstHatPiece:AspectSet = getExtra(state.global[pieceHatFirst_]);
            var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.extras, pieceHatNext_);
            for (piece in hatPieces) quantumPieceMoves.push(allMoves[piece[pieceMoveID_]]);
            quantumMoves = cast quantumPieceMoves;
        } else {
            moves = [];
        }
    }

    override private function _chooseMove(choice:Int):Void {
        var move:PickPieceMove = cast moves[choice];
        // A selection is made randomly
        if (remakeHat()) buildHat();
        move = pickMoveFromHat();
        setPiece(move.pieceTableID, move.reflection, move.rotation);
        signalChange();
    }

    override private function _chooseQuantumMove(choice:Int):Void {
        // The player's choice is selected
        var move:PickPieceMove = cast moves[choice];
        if (remakeHat()) buildHat();
        pickMoveFromHat(move);
        setPiece(move.pieceTableID, move.reflection, move.rotation);
    }

    private function buildPieceMoves():Void {

        // Every move has to be made before the game begins. These moves
        // are reused throughout the game to represent the hat's contents.

        allMoves = [];
        pickMove = {id:0};

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

        // Create a hat extra for every move
        var allPieces:Array<AspectSet> = [];
        for (move in allMoves) {
            move.hatIndex = numExtras();
            var piece:AspectSet = addExtra();
            piece[pieceMoveID_] = move.id;
            allPieces.push(piece);
        }

        allPieces.chainByAspect(ident_, pieceNext_, piecePrev_);
        state.global[pieceFirst_] = allPieces[0][ident_];
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

    private function pickMoveFromHat(move:PickPieceMove = null):PickPieceMove {

        var firstHatPiece:AspectSet = getExtra(state.global[pieceHatFirst_]);
        var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.extras, pieceHatNext_);

        // Because pieces are differently weighted, we need to use a binary search algo
        // to retrieve a picked piece

        // ...or maybe not. TODO: Revisit this

        var maxWeight:Float = 0;
        var weights:Array<Float> = [];
        for (piece in hatPieces) {
            weights.push(maxWeight);
            maxWeight += allMoves[piece[pieceMoveID_]].weight;
        }

        var pickedPiece:AspectSet = null;
        if (move == null) {
            var pick:Float = params.randomFunction() * maxWeight;
            pickedPiece = hatPieces[binarySearch(pick, weights)];
            move = allMoves[pickedPiece[pieceMoveID_]];
        } else {
            pickedPiece = getExtra(move.hatIndex);
        }


        state.global[piecesPicked_] = state.global[piecesPicked_] + 1;

        var nextPiece:AspectSet = pickedPiece.removeSet(state.extras, pieceHatNext_, pieceHatPrev_);

        if (pickedPiece == firstHatPiece) {
            firstHatPiece = nextPiece;
            if (firstHatPiece == null) state.global[pieceHatFirst_] = NULL;
            else state.global[pieceHatFirst_] = firstHatPiece[ident_];
        }

        return move;
    }

    private function buildHat():Void {
        var firstPiece:AspectSet = getExtra(state.global[pieceFirst_]);
        var allPieces:Array<AspectSet> = firstPiece.listToArray(state.extras, pieceNext_);
        allPieces.chainByAspect(ident_, pieceHatNext_, pieceHatPrev_);
        state.global[pieceHatFirst_] = firstPiece[ident_];
        state.global[piecesPicked_] = 0;
        state.global[pieceHatPlayer_] = state.global[currentPlayer_];
    }

    private function binarySearch(val:Float, list:Array<Float>):Int {

        function search(min:Int, max:Int):Int {

            var halfway:Int = Std.int((min + max) * 0.5);
            var output:Int = halfway;

            if (max < min) output = -1;
            else if (max - min == 1) output = (list[max] - val > val - list[min]) ? min : max;
            else if (list[halfway] > val) output = search(min, halfway);
            else if (list[halfway] < val) output = search(halfway, max);

            return output;
        }

        return search(0, list.length - 1);
    }

    // We fill the hat up again if it's empty
    private function remakeHat():Bool {
        return state.global[pieceHatPlayer_] != state.global[currentPlayer_] ||
                state.global[piecesPicked_] == params.hatSize;
    }
}
