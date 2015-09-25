package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Builder;
import net.rezmason.scourge.game.PieceTypes;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.aspect.AspectUtils;

class PickPieceBuilder extends Builder<PickPieceParams> {

    var allMoves:Array<PickPieceMove>;

    @card(PieceAspect.PIECE_NEXT, true) var pieceNext_;
    @card(PieceAspect.PIECE_PREV, true) var piecePrev_;
    @card(PieceAspect.PIECE_MOVE_ID, true) var pieceMoveID_;
    @global(PieceAspect.PIECE_FIRST, true) var pieceFirst_;

    override public function prime():Void {
        if (params.hatSize > params.pieceTableIDs.length) params.hatSize = params.pieceTableIDs.length;
        
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
        var allPieces = [];
        for (move in allMoves) {
            move.hatIndex = numCards();
            var piece = addCard();
            piece[pieceMoveID_] = move.id;
            allPieces.push(piece);
        }

        allPieces.chainByAspect(cardIdent_, pieceNext_, piecePrev_);
        state.global[pieceFirst_] = getID(allPieces[0]);
        params.pieceMoves = allMoves;
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
}
