package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Builder;
import net.rezmason.scourge.game.Piece;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.aspect.AspectUtils;

class PickPieceBuilder extends Builder<PickPieceParams> {

    var allMoves:Array<PickPieceMove>;

    @card(PieceAspect.PIECE_NEXT, true) var pieceNext_;
    @card(PieceAspect.PIECE_PREV, true) var piecePrev_;
    @card(PieceAspect.PIECE_MOVE_ID, true) var pieceMoveID_;
    @global(PieceAspect.PIECE_FIRST, true) var pieceFirst_;

    override public function prime():Void {

        var numPieceIDs = params.pieceIDs.length;
        if (params.hatSize > numPieceIDs) params.hatSize = numPieceIDs;
        
        // Every move has to be made before the game begins. These moves
        // are reused throughout the game to represent the hat's contents.

        allMoves = [];
        
        // We create the table of piece frequencies from the params

        var pieceFrequencies:Array<Null<Int>> = [];
        for (ike in 0...numPieceIDs) {
            if (pieceFrequencies[ike] == null) pieceFrequencies[ike] = 0;
            pieceFrequencies[ike]++;
        }

        // Create an move for every element being picked randomly

        for (ike in 0...numPieceIDs) {
            var freq:Null<Int> = pieceFrequencies[ike];
            if (freq == 0 || freq == null) continue;
            var freePiece:Piece = params.pieceLib.getPieceByID(params.pieceIDs[ike]);
            var numRotations = freePiece.numRotations;

            // A piece that can't be flipped or rotated has its multiple symmetries
            // added to the hat, and so it has more moves

            if (params.allowFlipping) {
                if (params.allowRotating) {
                    generateMove(ike, 0, 0, freq);
                } else {
                    var spinWeight:Int = Std.int(numRotations / 4);
                    for (rotation in 0...numRotations) generateMove(ike, 0, rotation, freq * spinWeight);
                }
            } else {
                for (flip in 0...freePiece.numReflections) {
                    if (params.allowRotating) {
                        generateMove(ike, flip, 0, freq);
                    } else {
                        var spinWeight:Int = Std.int(numRotations / 4);
                        for (rotation in 0...numRotations) generateMove(ike, flip, rotation, freq * spinWeight);
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

    private function generateMove(pieceTableIndex:Int, reflection:Int, rotation:Int, weight:Int):PickPieceMove {
        var move:PickPieceMove = {
            pieceTableIndex:pieceTableIndex,
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
