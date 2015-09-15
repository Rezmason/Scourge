package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;

using Lambda;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.pointers.Pointers;

class KillHeadlessBodyActor extends Actor<Dynamic> {

    @space(BodyAspect.BODY_NEXT, true) var bodyNext_;
    @space(BodyAspect.BODY_PREV, true) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS, true) var freshness_;
    @space(OwnershipAspect.IS_FILLED, true) var isFilled_;
    @space(OwnershipAspect.OCCUPIER, true) var occupier_;
    @player(BodyAspect.BODY_FIRST, true) var bodyFirst_;
    @player(BodyAspect.HEAD, true) var head_;
    @global(FreshnessAspect.MAX_FRESHNESS, true) var maxFreshness_;

    override private function _chooseMove(_):Void {

        // trace(state.spitBoard(plan));

        var maxFreshness:Int = state.global[maxFreshness_];

        // Check each player to see if they still have head spaces

        for (player in eachPlayer()) {
            var playerID:Int = getID(player);

            var head:Int = player[head_];

            if (head != NULL) {
                var bodyFirst:Int = player[bodyFirst_];
                var playerHead = getSpace(head);
                if (playerHead[occupier_] != playerID || playerHead[isFilled_] == FALSE) {

                    // Destroy the head and body

                    player[head_] = NULL;
                    var bodySpace = getSpace(bodyFirst);
                    for (space in bodySpace.listToArray(state.spaces, bodyNext_)) killCell(space, maxFreshness);
                    player[bodyFirst_] = NULL;
                    maxFreshness++;
                }
            }

        }

        state.global[maxFreshness_] = maxFreshness;

        // trace(state.spitBoard(plan));
        // trace('---');
    }

    function killCell(space:Space, maxFreshness:Int) {
        space[isFilled_] = FALSE;
        space[occupier_] = NULL;
        space[freshness_] = maxFreshness;
        space.removeSet(state.spaces, bodyNext_, bodyPrev_);
    }
}

