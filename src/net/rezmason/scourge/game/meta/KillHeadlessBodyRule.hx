package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;

using Lambda;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.utils.Pointers;

class KillHeadlessBodyRule extends BaseRule<Dynamic> {

    @space(BodyAspect.BODY_NEXT) var bodyNext_;
    @space(BodyAspect.BODY_PREV) var bodyPrev_;
    @space(FreshnessAspect.FRESHNESS) var freshness_;
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    override private function _chooseMove(choice:Int):Void {

        // trace(state.spitBoard(plan));

        var maxFreshness:Int = state.global[maxFreshness_];

        // Check each player to see if they still have head spaces

        for (player in eachPlayer()) {
            var playerID:Int = getID(player);

            var head:Int = player[head_];

            if (head != NULL) {
                var bodyFirst:Int = player[bodyFirst_];
                var playerHead:AspectSet = getSpace(head);
                if (playerHead[occupier_] != playerID || playerHead[isFilled_] == FALSE) {

                    // Destroy the head and body

                    player[head_] = NULL;
                    var bodySpace:AspectSet = getSpace(bodyFirst);
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

    function killCell(space:AspectSet, maxFreshness:Int):Void {
        space[isFilled_] = FALSE;
        space[occupier_] = NULL;
        space[freshness_] = maxFreshness;

        space.removeSet(state.spaces, bodyNext_, bodyPrev_);
    }
}

