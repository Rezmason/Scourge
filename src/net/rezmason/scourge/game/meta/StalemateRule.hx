package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.WinAspect;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;

using net.rezmason.utils.pointers.Pointers;

class StalemateRule extends BaseRule<StalemateParams> {

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(SkipAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @global(WinAspect.WINNER, true) var winner_;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    override private function _chooseMove(choice:Int):Void {

        var stalemate:Bool = true;

        if (state.global[winner_] != NULL) {
            stalemate = false;
        } else {
            for (player in eachPlayer()) {
                if (player[numConsecutiveSkips_] < params.maxSkips) {
                    stalemate = false;
                    break;
                }
            }
        }

        var largestArea:Int = -1;
        var largestPlayers:Array<Int> = null;

        if (stalemate) {
            for (player in eachPlayer()) {
                var playerID:Int = getID(player);
                var totalArea:Int = player[totalArea_];

                if (totalArea > largestArea) largestPlayers = [playerID];
                else if (totalArea == largestArea) largestPlayers.push(playerID);
            }

            state.global[winner_] = largestPlayers.pop();
            signalChange();
        }
    }
}

