package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Surveyor;
import net.rezmason.scourge.game.PieceTypes;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.aspect.AspectUtils;

class PickPieceSurveyor extends Surveyor<PickPieceParams> {

    private var allMoves:Array<PickPieceMove>;

    // This rule is surprisingly complex

    @card(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_;
    @card(PieceAspect.PIECE_MOVE_ID) var pieceMoveID_;

    @global(PieceAspect.PIECES_PICKED) var piecesPicked_;
    @global(PieceAspect.PIECE_HAT_FIRST) var pieceHatFirst_;
    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;

    @global(PieceAspect.PIECE_HAT_PLAYER) var pieceHatPlayer_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    // All this for an overglorified random piece picker!

    override public function prime():Void {
        allMoves = params.pieceMoves;
    }

    override public function update():Void {
        if (remakeHat()) {
            // The hat's been refilled; all piece moves are available as moves
            moves = cast allMoves.copy();
        } else if (state.global[pieceTableID_] == NULL) {
            // Iterate over the hat's contents and include the corresponding moves
            moves = [];
            var firstHatPiece = getCard(state.global[pieceHatFirst_]);
            var hatPieces = firstHatPiece.listToArray(state.cards, pieceHatNext_);
            for (piece in hatPieces) moves.push(allMoves[piece[pieceMoveID_]]);
        } else {
            moves = [];
        }
    }

    // We fill the hat up again if it's empty
    private function remakeHat():Bool {
        return state.global[pieceHatPlayer_] != state.global[currentPlayer_] ||
                state.global[piecesPicked_] == params.hatSize;
    }
}
