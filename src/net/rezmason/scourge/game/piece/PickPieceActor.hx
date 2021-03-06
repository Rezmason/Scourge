package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.Piece;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.aspect.AspectUtils;

class PickPieceActor extends Actor<PickPieceParams> {

    private var allMoves:Array<PickPieceMove>;

    @card(PieceAspect.PIECE_HAT_NEXT, true) var pieceHatNext_;
    @card(PieceAspect.PIECE_HAT_PREV, true) var pieceHatPrev_;

    @card(PieceAspect.PIECE_NEXT) var pieceNext_;
    
    @global(PieceAspect.PIECES_PICKED, true) var piecesPicked_;
    @global(PieceAspect.PIECE_FIRST, true) var pieceFirst_;
    @global(PieceAspect.PIECE_HAT_FIRST, true) var pieceHatFirst_;
    @global(PieceAspect.PIECE_REFLECTION, true) var pieceReflection_;
    @global(PieceAspect.PIECE_ROTATION, true) var pieceRotation_;
    @global(PieceAspect.PIECE_TABLE_INDEX, true) var pieceTableIndex_;

    @global(PieceAspect.PIECE_HAT_PLAYER, true) var pieceHatPlayer_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override public function prime():Void {
        buildHat();
    }

    override public function chooseMove(move:Move):Void {
        var pickPieceMove:PickPieceMove = cast move;
        if (shouldRemakeHat()) buildHat();
        pickMoveFromHat(pickPieceMove);
        setPiece(pickPieceMove.pieceTableIndex, pickPieceMove.reflection, pickPieceMove.rotation);
    }

    private function setPiece(pieceTableIndex:Int, reflection:Int, rotation:Int):Void {
        state.global[pieceTableIndex_] = pieceTableIndex;
        state.global[pieceReflection_] = reflection;
        state.global[pieceRotation_] = rotation;
    }

    private function pickMoveFromHat(move:PickPieceMove):PickPieceMove {
        var firstHatPiece = getCard(state.global[pieceHatFirst_]);
        var pickedPiece = getCard(move.hatIndex);
        state.global[piecesPicked_] = state.global[piecesPicked_] + 1;

        var nextPiece = pickedPiece.removeSet(state.cards, pieceHatNext_, pieceHatPrev_);

        if (pickedPiece == firstHatPiece) {
            firstHatPiece = nextPiece;
            if (firstHatPiece == null) state.global[pieceHatFirst_] = NULL;
            else state.global[pieceHatFirst_] = getID(firstHatPiece);
        }

        return move;
    }

    private function buildHat():Void {
        var firstPiece = getCard(state.global[pieceFirst_]);
        var allPieces = firstPiece.listToArray(state.cards, pieceNext_);
        allPieces.chainByAspect(cardIdent_, pieceHatNext_, pieceHatPrev_);
        state.global[pieceHatFirst_] = getID(firstPiece);
        state.global[piecesPicked_] = 0;
        state.global[pieceHatPlayer_] = state.global[currentPlayer_];
    }

    // We fill the hat up again if it's empty
    private function shouldRemakeHat():Bool {
        return state.global[pieceHatPlayer_] != state.global[currentPlayer_] ||
                state.global[piecesPicked_] == params.hatSize;
    }
}
