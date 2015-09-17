package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.aspect.AspectUtils;

class BiteActor extends Actor<BiteParams> {

    @space(BodyAspect.BODY_NEXT, true) var bodyNext_;
    @space(BodyAspect.BODY_PREV, true) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @space(OwnershipAspect.IS_FILLED, true) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BiteAspect.NUM_BITES, true) var numBites_;
    @player(BodyAspect.BODY_FIRST, true) var bodyFirst_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var movePool:Array<BiteMove> = [];
    private var allMoves:Array<BiteMove> = [];

    override public function prime():Void {
        for (player in eachPlayer()) player[numBites_] = params.startingBites;
    }

    override public function chooseMove(move:Move):Void {

        var biteMove:BiteMove = cast move;

        if (biteMove.targetSpace != NULL) {

            // Grab data from the move

            var currentPlayer:Int = state.global[currentPlayer_];

            var maxFreshness:Int = state.global[maxFreshness_];
            var numBites:Int = getPlayer(currentPlayer)[numBites_] - 1;

            // Find the cells removed from each player

            var bitSpacesByPlayer:Array<Array<Space>> = [];
            for (player in eachPlayer()) bitSpacesByPlayer.push([]);

            for (bitSpaceID in biteMove.bitSpaces) {
                var bitSpace:Space = getSpace(bitSpaceID);
                bitSpacesByPlayer[bitSpace[occupier_]].push(bitSpace);
            }

            // Remove the appropriate cells from each player

            for (player in eachPlayer()) {
                var bitSpaces:Array<Space> = bitSpacesByPlayer[getID(player)];
                var bodyFirst:Int = player[bodyFirst_];
                for (bitSpace in bitSpaces) bodyFirst = killCell(bitSpace, maxFreshness++, bodyFirst);
                player[bodyFirst_] = bodyFirst;
            }

            state.global[maxFreshness_] = maxFreshness;
            getPlayer(currentPlayer)[numBites_] = numBites;
        }

        signalChange();
    }

    inline function killCell(space:Space, freshness:Int, firstIndex:Int):Int {
        if (space[isFilled_] == TRUE) {
            var nextSpace:Space = space.removeSet(state.spaces, bodyNext_, bodyPrev_);
            if (firstIndex == getID(space)) firstIndex = nextSpace == null ? NULL : getID(nextSpace);
            space[isFilled_] = FALSE;
        }

        space[occupier_] = NULL;
        space[freshness_] = freshness;

        return firstIndex;
    }
}
