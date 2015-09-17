package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.scourge.game.meta.SkipAspect;

using net.rezmason.praxis.aspect.AspectUtils;

class DropPieceActor extends Actor<DropPieceParams> {

    @space(BodyAspect.BODY_NEXT, true) var bodyNext_;
    @space(BodyAspect.BODY_PREV, true) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @space(OwnershipAspect.IS_FILLED, true) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BodyAspect.BODY_FIRST, true) var bodyFirst_;
    @player(SkipAspect.NUM_CONSECUTIVE_SKIPS, true) var numConsecutiveSkips_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;
    @global(PieceAspect.PIECE_TABLE_ID, true) var pieceTableID_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override public function chooseMove(move:Move):Void {
        var dropPieceMove:DropPieceMove = cast move;
        var currentPlayer:Int = state.global[currentPlayer_];
        var player = getPlayer(currentPlayer);

        if (dropPieceMove.targetSpace != NULL) {
            var maxFreshness:Int = state.global[maxFreshness_];
            var bodySpace = getSpace(getPlayer(currentPlayer)[bodyFirst_]);
            for (id in dropPieceMove.addedSpaces) bodySpace = fillAndOccupyCell(getSpace(id), currentPlayer, maxFreshness, bodySpace);
            player[bodyFirst_] = getID(bodySpace);
            state.global[maxFreshness_] = maxFreshness + 1;
            player[numConsecutiveSkips_] = 0;
        } else {
            player[numConsecutiveSkips_] = player[numConsecutiveSkips_] + 1;
        }

        state.global[pieceTableID_] = NULL;
        signalChange();
    }

    inline function fillAndOccupyCell(me:Space, currentPlayer:Int, maxFreshness:Int, bodySpace:Space) {
        if (me[occupier_] != currentPlayer || me[isFilled_] == FALSE) me[freshness_] = maxFreshness;
        me[occupier_] = currentPlayer;
        me[isFilled_] = TRUE;
        return bodySpace.addSet(me, state.spaces, spaceIdent_, bodyNext_, bodyPrev_);
    }
}
